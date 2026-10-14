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
  String launcherId,
  ClientMessage message,
});

/// App-lifetime request journal: page disposal or reconnect must not forget an
/// accepted mutation's idempotency key. Never evict an uncertain request.
class AgentMutationJournal {
  final _entries = <(String, String), _AgentMutation>{};
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
  String? _peer, _room, _launcherId;
  int? _roomEpoch;
  bool _disposed = false;
  IChannel? _channel;
  StreamSubscription<ServerMessage>? _messages;
  StreamSubscription<ConnectionStatus>? _status;
  StreamSubscription<Map<String, List<RoomInfo>>>? _rooms;
  final _invalidations = StreamController<void>.broadcast();
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
    _channel = null;
    for (final p in _pending.values) {
      p.timer.cancel();
      p.completer.completeError(
        AgentFailure(
          'Host disconnected or session changed. Return home and select it again.',
          outcomeUnknown: p.type != 'agent_list_result',
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
      AgentListResult() => message.inReplyTo,
      AgentMutationResult() => message.inReplyTo,
      ErrorMessage() => message.inReplyTo,
      _ => null,
    };
    final p = _pending[id];
    if (p == null) return;
    if (message is! ErrorMessage &&
        (message is AgentListResult
                ? 'agent_list_result'
                : (message as AgentMutationResult).type) !=
            p.type) {
      return;
    }
    _pending.remove(id);
    p.timer.cancel();
    final key = (_peer!, _room!);
    if (_journal._entries[key]?.id == id) _journal._entries.remove(key);
    if (message is ErrorMessage) {
      p.completer.completeError(AgentFailure(message.message));
    } else {
      p.completer.complete(message);
    }
  }

  Future<ServerMessage> _request(
    String type,
    ClientMessage Function(String) create, {
    _AgentMutation? replay,
  }) async {
    if (!_valid) {
      _invalidate();
      throw const AgentFailure(
        'Host disconnected or session changed. Return home and select it again.',
      );
    }
    final key = (_peer!, _room!);
    final id = replay?.id ?? uuid7();
    final mutation = type != 'agent_list_result';
    if (mutation && _launcherId == null) {
      throw const AgentFailure(
        'Refresh launcher capabilities before starting an operation.',
      );
    }
    final previous = _journal._entries[key];
    if (mutation && previous != null && previous.id != id) {
      throw const AgentFailure(
        'Refresh to settle the previous operation before starting another.',
        outcomeUnknown: true,
      );
    }
    final pending = _pending[id];
    if (pending != null) return pending.completer.future;
    final request = replay?.message ?? create(id);
    if (mutation) {
      if (previous == null &&
          _journal._entries.length >= AgentMutationJournal._limit) {
        throw const AgentFailure(
          'Resolve pending agent operations before managing more hosts.',
        );
      }
      _journal._entries[key] = (
        id: id,
        type: type,
        launcherId: _launcherId!,
        message: request,
      );
    }
    final completer = Completer<ServerMessage>();
    final deadline = type == 'agent_list_result' ? timeout : mutationTimeout;
    final timer = Timer(deadline, () {
      final p = _pending.remove(id);
      p?.completer.completeError(
        AgentFailure(
          type == 'agent_list_result'
              ? 'No capability reply. Update the host Remote Pi extension and try again.'
              : 'Host response timed out. Refresh before retrying; the operation may have completed.',
          outcomeUnknown: type != 'agent_list_result',
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
          p.timer.cancel();
          p.completer.completeError(
            AgentFailure(
              'Could not send to selected host. Refresh before retrying.',
              outcomeUnknown: type != 'agent_list_result',
            ),
          );
        }
      }),
    );
    return completer.future;
  }

  @override
  Future<AgentAvailability> list() async {
    final snapshot = await _fetchList();
    final key = (_peer!, _room!);
    final mutation = _journal._entries[key];
    if (mutation != null) {
      if (snapshot.launcherId != mutation.launcherId) {
        _journal._entries.remove(key);
        throw const AgentFailure(
          'The launching session changed. The previous operation was not retried. Refresh and confirm a new Start if needed.',
        );
      }
      // A snapshot only verifies incarnation; it cannot settle pending admission.
      // Replay the exact request. Host checks the incarnation again at execution.
      try {
        await _request(
          mutation.type,
          (_) => mutation.message,
          replay: mutation,
        );
      } on AgentFailure catch (error) {
        if (error.outcomeUnknown || !_valid) rethrow;
        // A correlated host error is a settled outcome. Now fetch its records.
      }
      refreshDiscovery();
      return _fetchList();
    }
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
    _launcherId = result.launcherId;
    return result;
  }

  @override
  Future<ManagedAgent> launch(String cwd, String? name) async {
    final error = validateAgentInput(cwd, name);
    if (error != null) throw AgentFailure(error);
    final reply = await _request(
      'agent_launch_result',
      (id) => AgentLaunch(id, cwd, name, _launcherId!),
    );
    refreshDiscovery();
    return (reply as AgentMutationResult).agent;
  }

  @override
  Future<ManagedAgent> stop(String agentId) async =>
      ((await _request('agent_stop_result', (id) => AgentStop(id, agentId)))
              as AgentMutationResult)
          .agent;
  @override
  void refreshDiscovery() {
    if (_valid) _conn.refreshDiscovery();
  }

  @override
  void dispose() {
    _disposed = true;
    _messages?.cancel();
    _status?.cancel();
    _rooms?.cancel();
    _invalidate();
    _invalidations.close();
  }
}
