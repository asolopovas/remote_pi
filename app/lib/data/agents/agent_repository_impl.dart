import 'dart:async';
import 'package:app/data/transport/channel.dart';
import 'package:app/data/transport/connection_manager.dart';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/pairing/storage.dart';
import 'package:app/protocol/protocol.dart';
import 'package:app/protocol/uuid7.dart';

/// Each page owns one pinned channel lease. Reconnect never renews it silently.
class AgentRepositoryImpl extends AgentRepository {
  AgentRepositoryImpl(
    this._conn,
    this._storage, {
    this.timeout = const Duration(seconds: 20),
    this.mutationTimeout = const Duration(seconds: 35),
  });
  final ConnectionManager _conn;
  final PairingStorage _storage;
  final Duration timeout;

  /// Host readiness (20s) plus failed-child cleanup (up to 6s), with margin.
  final Duration mutationTimeout;
  String? _peer, _room;
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
        const AgentFailure(
          'Host disconnected or session changed. Return home and select it again.',
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
    if (message is ErrorMessage) {
      p.completer.completeError(AgentFailure(message.message));
    } else {
      p.completer.complete(message);
    }
  }

  Future<ServerMessage> _request(
    String type,
    ClientMessage Function(String) create,
  ) async {
    if (!_valid) {
      _invalidate();
      throw const AgentFailure(
        'Host disconnected or session changed. Return home and select it again.',
      );
    }
    final id = uuid7();
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
      _channel!.send(create(id)).catchError((Object error, StackTrace stack) {
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
  Future<AgentAvailability> list() async =>
      ((await _request('agent_list_result', AgentList.new)) as AgentListResult)
          .availability;
  @override
  Future<ManagedAgent> launch(String cwd, String? name) async {
    final error = validateAgentInput(cwd, name);
    if (error != null) throw AgentFailure(error);
    final reply = await _request(
      'agent_launch_result',
      (id) => AgentLaunch(id, cwd, name),
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
