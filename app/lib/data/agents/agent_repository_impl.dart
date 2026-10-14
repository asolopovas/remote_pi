import 'dart:async';
import 'package:app/data/transport/channel.dart';
import 'package:app/data/transport/connection_manager.dart';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/pairing/storage.dart';
import 'package:app/protocol/protocol.dart';
import 'package:app/protocol/uuid7.dart';

typedef _AgentMutation = ({
  String id,
  String type,
  (String, String) incarnation,
});

/// App-lifetime request journal: page disposal or reconnect must not forget an
/// uncertain launch. No payload or PIN is retained, and nothing is replayed.
class AgentMutationJournal {
  final _entries = <(String, String), _AgentMutation>{};
  final _history = <(String, String), List<_AgentMutation>>{};
  static const _limit = 32;
}

/// Each page owns one pinned channel lease. Reconnect never renews it silently.
class AgentRepositoryImpl extends AgentRepository {
  AgentRepositoryImpl(
    this._conn,
    this._storage,
    this._journal, {
    this.timeout = const Duration(seconds: 20),
    this.mutationTimeout = const Duration(seconds: 35),
  });
  final ConnectionManager _conn;
  final PairingStorage _storage;
  final AgentMutationJournal _journal;
  final Duration timeout;

  /// Host readiness (20s) plus failed-child cleanup (up to 6s), with margin.
  final Duration mutationTimeout;
  String? _peer, _room;
  (String, String)? _incarnation;
  LauncherStatus? _security;
  List<LauncherProject> _projects = const [];
  Timer? _expiry;
  bool _reconciled = false;
  @override
  bool get hasUnknownLaunch =>
      _peer != null &&
      _incarnation != null &&
      (_journal._entries[(_peer!, _room!)]?.incarnation == _incarnation ||
          (_journal._history[(_peer!, _room!)]?.any(
                (entry) => entry.incarnation == _incarnation,
              ) ??
              false));
  @override
  LauncherStatus? get launcherStatus => _security;
  @override
  List<LauncherProject> get projects => _projects;
  void _revoke() {
    _reconciled = false;
    _security = null;
    _projects = const [];
    _expiry?.cancel();
  }

  void _accept(LauncherStatus value) {
    final changed =
        _security?.launcherId != value.launcherId ||
        _security?.epoch != value.epoch;
    if (changed || !value.permitsControl) _projects = const [];
    _security = value;
    _incarnation = (value.launcherId, value.epoch);
    _expiry?.cancel();
    if (value.permitsControl) {
      _expiry = Timer(
        Duration(
          milliseconds:
              value.expiresAt! - DateTime.now().millisecondsSinceEpoch,
        ),
        () {
          _revoke();
          if (!_invalidations.isClosed) _invalidations.add(null);
        },
      );
    }
  }

  @override
  Future<void> status() async {
    _revoke();
    final result = await _request(
      'launcher_status_result',
      (id) => LauncherRequest('launcher_status', id),
    );
    _accept((result as LauncherStatusResult).status);
  }

  @override
  Future<void> unlock(String pin) async {
    final security = _security;
    if (security == null || !security.configured) {
      throw const AgentFailure(
        'Configure the PIN and registered projects on the host.',
      );
    }
    if (!RegExp(r'^\d{6,12}$').hasMatch(pin)) {
      throw const AgentFailure('PIN must be 6–12 digits.');
    }
    if (security.cooldownUntil > DateTime.now().millisecondsSinceEpoch) {
      throw const AgentFailure(
        'PIN cooldown active. Wait before trying again.',
      );
    }
    _revoke();
    final pending = _request(
      'launcher_status_result',
      (id) =>
          LauncherRequest('launcher_unlock', id, status: security, pin: pin),
    );
    pin = '';
    final result = await pending;
    _accept((result as LauncherStatusResult).status);
  }

  @override
  Future<bool> lock({bool shutdown = false}) async {
    final security = _security;
    _revoke();
    if (security == null) {
      throw const AgentFailure(
        'Refresh launcher status before locking. Local control is revoked.',
      );
    }
    final result = await _request(
      shutdown ? 'launcher_shutdown_result' : 'launcher_status_result',
      (id) => LauncherRequest(
        shutdown ? 'launcher_shutdown' : 'launcher_lock',
        id,
        status: security,
      ),
    );
    final reply = result as LauncherStatusResult;
    // Never restore local authority from a lock/shutdown response.
    _accept(
      LauncherStatus(
        launcherId: reply.status.launcherId,
        epoch: reply.status.epoch,
        configured: reply.status.configured,
        unlocked: false,
        expiresAt: null,
        cooldownUntil: reply.status.cooldownUntil,
      ),
    );
    return reply.stopped ?? true;
  }

  void _requireUnlocked() {
    if (_security?.permitsControl != true) {
      throw const AgentFailure('Unlock the host launcher first.');
    }
  }

  int? _roomEpoch;
  bool _disposed = false;
  IChannel? _channel;
  StreamSubscription<ServerMessage>? _messages;
  StreamSubscription<ConnectionStatus>? _status;
  StreamSubscription<Map<String, List<RoomInfo>>>? _rooms;
  final _invalidations = StreamController<void>.broadcast();
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  final _pending =
      <
        String,
        ({Completer<ServerMessage> completer, Timer timer, String type})
      >{};
  @override
  Stream<void> get invalidations => _invalidations.stream;
  bool get _valid =>
      _channel != null &&
      identical(_conn.channel, _channel) &&
      _conn.activePeer?.remoteEpk == _peer &&
      _conn.activeRoomId == _room &&
      _conn.roomSelectionEpoch == _roomEpoch &&
      _conn.isRoomLive(_peer!, _room!);

  @override
  Future<void> bind(String peer, String room) async {
    final peers = await _storage.listPeers();
    if (_disposed) throw const AgentFailure('Agent page closed.');
    final matches = peers.where((p) => p.remoteEpk == peer);
    if (matches.isEmpty || !_conn.isRoomLive(peer, room)) {
      throw const AgentFailure('Selected paired session is offline.');
    }
    await _conn.switchTo(matches.first.copyWith(roomId: room));
    if (_disposed) throw const AgentFailure('Agent page closed.');
    if (_conn.activePeer?.remoteEpk != peer ||
        _conn.status is! StatusOnline ||
        !_conn.isRoomLive(peer, room)) {
      throw const AgentFailure(
        'Host changed or disconnected. Return home and select it again.',
      );
    }
    _conn.switchRoom(room);
    _peer = peer;
    _room = room;
    _roomEpoch = _conn.roomSelectionEpoch;
    _channel = _conn.channel;
    _messages = _channel!.serverMessages.listen(
      _onMessage,
      onDone: _invalidate,
    );
    _status = _conn.statusStream.listen((_) {
      if (!_valid) _invalidate();
    });
    _rooms = _conn.roomsStream.listen((_) {
      if (!_valid) _invalidate();
    });
  }

  void _invalidate() {
    _revoke();
    _channel = null;
    for (final p in _pending.values) {
      p.timer.cancel();
      p.completer.completeError(
        AgentFailure(
          'Host disconnected or session changed. Return home and select it again.',
          outcomeUnknown:
              p.type == 'agent_launch_result' || p.type == 'agent_stop_result',
        ),
      );
    }
    _pending.clear();
    if (!_invalidations.isClosed) _invalidations.add(null);
  }

  void _onMessage(ServerMessage message) {
    if (!_valid) {
      _invalidate();
      return;
    }
    final id = switch (message) {
      LauncherStatusResult() => message.inReplyTo,
      ProjectListResult() => message.inReplyTo,
      AgentListResult() => message.inReplyTo,
      AgentMutationResult() => message.inReplyTo,
      ErrorMessage() => message.inReplyTo,
      _ => null,
    };
    final key = (_peer!, _room!);
    if (message is AgentMutationResult || message is ErrorMessage) {
      bool settles(_AgentMutation entry) =>
          entry.id == id &&
          (message is ErrorMessage ||
              (message as AgentMutationResult).type == entry.type);
      final entry = _journal._entries[key];
      if (entry != null && settles(entry)) _journal._entries.remove(key);
      _journal._history[key]?.removeWhere(settles);
      if (!_changes.isClosed) _changes.add(null);
    }
    final p = _pending[id];
    if (p == null) return;
    if (message is! ErrorMessage &&
        (message is LauncherStatusResult
                ? message.type
                : message is ProjectListResult
                ? 'project_list_result'
                : message is AgentListResult
                ? 'agent_list_result'
                : (message as AgentMutationResult).type) !=
            p.type) {
      return;
    }
    _pending.remove(id);
    p.timer.cancel();

    if (message is ErrorMessage) {
      _revoke();
      p.completer.completeError(AgentFailure(message.message));
    } else {
      p.completer.complete(message);
    }
  }

  Future<ServerMessage> _request(
    String type,
    ClientMessage Function(String) create,
  ) {
    if (!_valid) {
      _invalidate();
      throw const AgentFailure(
        'Host disconnected or session changed. Return home and select it again.',
      );
    }
    final key = (_peer!, _room!);
    final id = uuid7();
    final mutation =
        type == 'agent_launch_result' || type == 'agent_stop_result';
    if (mutation && _incarnation == null) {
      throw const AgentFailure(
        'Refresh launcher capabilities before starting an operation.',
      );
    }
    final previous = _journal._entries[key];
    if (type == 'agent_launch_result' &&
        previous != null &&
        previous.id != id) {
      throw const AgentFailure(
        'Refresh to settle the previous operation before starting another.',
        outcomeUnknown: true,
      );
    }
    final pending = _pending[id];
    if (pending != null) return pending.completer.future;
    final request = create(id);
    // Timers retain only operation metadata, never the PIN-bearing message.
    final securityMutation =
        request is LauncherRequest &&
        const [
          'launcher_unlock',
          'launcher_lock',
          'launcher_shutdown',
        ].contains(request.type);
    if (type == 'agent_launch_result') {
      if (previous == null &&
          _journal._entries.length >= AgentMutationJournal._limit) {
        throw const AgentFailure(
          'Resolve pending agent operations before managing more hosts.',
        );
      }
      _journal._entries[key] = (id: id, type: type, incarnation: _incarnation!);
    }
    final completer = Completer<ServerMessage>();
    final deadline = mutation ? mutationTimeout : timeout;
    final timer = Timer(deadline, () {
      final p = _pending.remove(id);
      _revoke();
      p?.completer.completeError(
        AgentFailure(
          mutation
              ? 'Host response timed out. Refresh before retrying; the operation may have completed.'
              : securityMutation
              ? 'Local control revoked. Host unlock/lock/stop outcome unknown. Refresh status; this action was not retried.'
              : 'No capability reply. Update/setup the host Remote Pi extension and try again.',
          outcomeUnknown: mutation || securityMutation,
        ),
      );
    });
    _pending[id] = (completer: completer, timer: timer, type: type);
    // Send synchronously against the captured channel, never after an async target lookup.
    unawaited(
      Future<void>.sync(() => _channel!.send(request)).catchError((
        Object error,
        StackTrace stack,
      ) {
        final p = _pending.remove(id);
        if (p != null) {
          _revoke();
          p.timer.cancel();
          p.completer.completeError(
            AgentFailure(
              'Could not send to selected host. Refresh before retrying.',
              outcomeUnknown: mutation || securityMutation,
            ),
          );
        }
      }),
    );
    return completer.future;
  }

  @override
  Future<AgentAvailability> list() async {
    await status();
    _requireUnlocked();
    final projects = await _request(
      'project_list_result',
      (id) => LauncherRequest('project_list', id),
    );
    _requireUnlocked();
    _projects = (projects as ProjectListResult).projects;
    final snapshot = await _fetchList();
    final key = (_peer!, _room!);
    final mutation = _journal._entries[key];
    if (mutation != null && mutation.incarnation != _incarnation) {
      _journal._entries.remove(key);
    }
    _requireUnlocked();
    _reconciled = true;
    return snapshot;
  }

  Future<AgentAvailability> _fetchList() async {
    final result =
        ((await _request('agent_list_result', AgentList.new))
                as AgentListResult)
            .availability;
    if (result.available &&
        (result.launcherId == null || result.launcherId!.isEmpty)) {
      throw const AgentFailure(
        'Update the host Remote Pi extension: launcher identity is unavailable.',
      );
    }
    if (result.launcherId != _security?.launcherId) {
      _revoke();
      throw const AgentFailure(
        'Launcher incarnation changed. Refresh and unlock again.',
      );
    }
    return result;
  }

  @override
  Future<ManagedAgent> launch(
    String projectId,
    String? name, {
    bool acknowledgeUnknown = false,
  }) async {
    _requireUnlocked();
    if (!_reconciled) {
      throw const AgentFailure(
        'Refresh security, projects and agents before starting.',
        outcomeUnknown: true,
      );
    }
    if (!_projects.any((p) => p.projectId == projectId)) {
      throw const AgentFailure('Select a registered project.');
    }
    final error = validateAgentInput(projectId, name);
    if (error != null) throw AgentFailure(error);
    final key = (_peer!, _room!);
    final previous = _journal._entries[key];
    if (hasUnknownLaunch && (!acknowledgeUnknown || !_reconciled)) {
      throw const AgentFailure(
        'Outcome unknown; it may still start/appear. Refresh, then explicitly confirm another Start.',
        outcomeUnknown: true,
      );
    }
    if (previous != null) {
      final history = _journal._history.putIfAbsent(key, () => []);
      if (history.length >= AgentMutationJournal._limit) {
        throw const AgentFailure(
          'Too many unresolved attempts. Check the host.',
        );
      }
      history.add(previous);
      _journal._entries.remove(key);
    }
    _reconciled = false;
    final reply = await _request(
      'agent_launch_result',
      (id) => LauncherRequest(
        'project_launch',
        id,
        status: _security!,
        projectId: projectId,
        name: name,
      ),
    );
    _reconciled = true;
    refreshDiscovery();
    return (reply as AgentMutationResult).agent;
  }

  @override
  Future<ManagedAgent> stop(String agentId) async {
    _requireUnlocked();
    return ((await _request(
              'agent_stop_result',
              (id) => LauncherRequest(
                'launcher_agent_stop',
                id,
                status: _security!,
                agentId: agentId,
              ),
            ))
            as AgentMutationResult)
        .agent;
  }

  @override
  void refreshDiscovery() {
    if (_valid) _conn.refreshDiscovery();
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    _messages?.cancel();
    _status?.cancel();
    _rooms?.cancel();
    _invalidate();
    _invalidations.close();
    _changes.close();
  }
}
