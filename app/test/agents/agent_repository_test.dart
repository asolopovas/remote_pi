import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app/data/agents/agent_repository_impl.dart';
import 'package:app/data/transport/channel.dart';
import 'package:app/data/transport/connection_manager.dart';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/pairing/storage.dart';
import 'package:app/protocol/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

const peer = PeerRecord(
  remoteEpk: 'paired-host',
  sessionName: 'Host',
  relayUrl: 'ws://unused',
  pairedAt: '2026-01-01',
);

class Storage extends PairingStorage {
  @override
  Future<List<PeerRecord>> listPeers() async => [peer];
}

class Channel implements IChannel {
  final messages = StreamController<ServerMessage>.broadcast();
  final sent = <ClientMessage>[];
  @override
  Stream<ServerMessage> get serverMessages => messages.stream;
  @override
  Future<void> send(ClientMessage message) async {
    sent.add(message);
  }

  @override
  Future<void> close() async {}
}

class Connection extends ConnectionManager {
  Connection(this.current)
    : super(factory: (_, _) async => current!, storage: Storage());
  IChannel? current;
  String room = 'launcher';
  int epoch = 0;
  @override
  int get roomSelectionEpoch => epoch;
  PeerRecord selected = peer;
  final statuses = StreamController<ConnectionStatus>.broadcast();
  final rooms = StreamController<Map<String, List<RoomInfo>>>.broadcast();
  @override
  IChannel? get channel => current;
  @override
  ConnectionStatus get status =>
      current == null ? const StatusNoPeer() : StatusOnline(current!);
  @override
  Stream<ConnectionStatus> get statusStream => statuses.stream;
  @override
  Stream<Map<String, List<RoomInfo>>> get roomsStream => rooms.stream;
  @override
  PeerRecord get activePeer => selected;
  @override
  String get activeRoomId => room;
  @override
  bool isRoomLive(String epk, String roomId) => current != null;
  @override
  Future<void> switchTo(PeerRecord p) async {
    selected = p;
  }

  @override
  void switchRoom(String r) {
    epoch++;
    room = r;
    rooms.add({});
  }

  @override
  void refreshDiscovery() {}
}

const available = AgentAvailability(
  available: true,
  cwd: '/project',
  maxAgents: 4,
  agents: [],
);
Future<void> tick() => Future<void>.delayed(Duration.zero);
void main() {
  test('frozen wire fixtures encode exact requests and parse replies', () {
    final fixture =
        jsonDecode(
              File(
                'test/protocol/fixtures/agent_management.json',
              ).readAsStringSync(),
            )
            as Map;
    final requests = [
      AgentList('list-1'),
      AgentLaunch('launch-1', '/projects/pi', 'Phone agent'),
      AgentLaunch('launch-2', '/projects/pi', null),
      AgentStop('stop-1', 'agent-1'),
    ];
    expect(requests.map((r) => r.toJson()).toList(), fixture['requests']);
    final replies = (fixture['replies'] as List)
        .map((r) => ServerMessage.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
    expect((replies[0] as AgentListResult).availability.cwd, '/projects/pi');
    expect((replies[1] as AgentListResult).availability.available, false);
    expect((replies[2] as AgentMutationResult).agent.roomId, 'room-agent-1');
    expect((replies[3] as AgentMutationResult).agent.state, 'stopped');
    expect((replies[4] as ErrorMessage).inReplyTo, 'launch-2');
  });
  group('pinned repository', () {
    late Channel channel;
    late Connection conn;
    late AgentRepositoryImpl repo;
    setUp(() async {
      channel = Channel();
      conn = Connection(channel);
      repo = AgentRepositoryImpl(
        conn,
        Storage(),
        timeout: const Duration(milliseconds: 40),
      );
      await repo.bind(peer.remoteEpk, 'launcher');
      await tick();
    });
    tearDown(() async {
      repo.dispose();
      await tick();
      await channel.messages.close();
      await conn.statuses.close();
      await conn.rooms.close();
      conn.dispose();
    });
    test('ignores uncorrelated and wrong reply type, consumes once', () async {
      final pending = repo.list();
      final id = (channel.sent.last as AgentList).id;
      channel.messages.add(AgentListResult('stale', available));
      channel.messages.add(
        AgentMutationResult(
          'agent_stop_result',
          id,
          const ManagedAgent(
            agentId: 'a',
            name: 'a',
            cwd: '/p',
            roomId: 'a',
            state: 'stopped',
          ),
        ),
      );
      channel.messages.add(AgentListResult(id, available));
      expect(await pending, available);
      channel.messages.add(AgentListResult(id, available));
      await tick();
    });
    test('old extension timeout explicitly recommends update', () async {
      await expectLater(
        repo.list(),
        throwsA(
          isA<AgentFailure>().having(
            (e) => e.message,
            'message',
            contains('Update'),
          ),
        ),
      );
    });
    test(
      'launch timeout marks outcome unknown for mandatory reconciliation',
      () async {
        await expectLater(
          repo.launch('/p', null),
          throwsA(
            isA<AgentFailure>().having(
              (e) => e.outcomeUnknown,
              'unknown outcome',
              true,
            ),
          ),
        );
      },
    );
    test('correlated error is human readable', () async {
      final pending = repo.list();
      channel.messages.add(
        ErrorMessage(
          inReplyTo: (channel.sent.last as AgentList).id,
          code: 'invalid_message',
          message: 'Unavailable',
        ),
      );
      await expectLater(
        pending,
        throwsA(
          isA<AgentFailure>().having(
            (e) => e.message,
            'message',
            'Unavailable',
          ),
        ),
      );
    });
    test('disconnect fails pending and reconnect cannot renew lease', () async {
      final pending = repo.list();
      final assertion = expectLater(pending, throwsA(isA<AgentFailure>()));
      conn.current = null;
      conn.statuses.add(const StatusNoPeer());
      await assertion;
      conn.current = Channel();
      await expectLater(repo.launch('/p', null), throwsA(isA<AgentFailure>()));
      expect(channel.sent.length, 1);
    });
    test('room switch and stale reply fail pending without new send', () async {
      final pending = repo.list();
      final assertion = expectLater(pending, throwsA(isA<AgentFailure>()));
      final id = (channel.sent.last as AgentList).id;
      conn.switchRoom('another');
      channel.messages.add(AgentListResult(id, available));
      await assertion;
      await expectLater(repo.list(), throwsA(isA<AgentFailure>()));
      expect(channel.sent.length, 1);
    });
    test('channel replacement even on same host rejects responses', () async {
      final pending = repo.list();
      final assertion = expectLater(pending, throwsA(isA<AgentFailure>()));
      conn.current = Channel();
      conn.statuses.add(StatusOnline(conn.current!));
      await assertion;
    });
    test('away-and-back switch cannot revive pending request', () async {
      final pending = repo.list();
      final assertion = expectLater(pending, throwsA(isA<AgentFailure>()));
      conn.switchRoom('other');
      conn.switchRoom('launcher');
      channel.messages.add(
        AgentListResult((channel.sent.last as AgentList).id, available),
      );
      await assertion;
    });
  });
}
