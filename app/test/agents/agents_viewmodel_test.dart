import 'dart:async';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/agents/viewmodels/agents_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

const agent = ManagedAgent(
  agentId: 'managed',
  name: 'New Pi',
  cwd: '/project',
  roomId: 'new-room',
  state: 'running',
);

class Repo extends AgentRepository {
  AgentAvailability availability = const AgentAvailability(
    available: true,
    cwd: '/project',
    maxAgents: 4,
    agents: [agent],
  );
  int launches = 0, stops = 0;
  final invalid = StreamController<void>.broadcast();
  Completer<ManagedAgent>? pending;
  @override
  Stream<void> get invalidations => invalid.stream;
  @override
  Future<void> bind(String peer, String room) async {}
  @override
  Future<AgentAvailability> list() async => availability;
  @override
  Future<ManagedAgent> launch(String cwd, String? name) async {
    launches++;
    return pending == null ? agent : pending!.future;
  }

  @override
  Future<ManagedAgent> stop(String agentId) async {
    stops++;
    return agent;
  }

  @override
  void refreshDiscovery() {}
  @override
  void dispose() {
    invalid.close();
  }
}

void main() {
  test('confirmation, duplicate suppression and managed-only stop', () async {
    final repo = Repo();
    final subject = AgentsViewModel(repo);
    await subject.initialize('peer', 'room');
    await subject.launch('/project', null, confirmed: false);
    expect(repo.launches, 0);
    repo.pending = Completer<ManagedAgent>();
    final start = subject.launch('/project', null, confirmed: true);
    await subject.launch('/project', null, confirmed: true);
    expect(repo.launches, 1);
    repo.pending!.complete(agent);
    await start;
    expect(subject.state.availability!.agents.length, 1);
    await subject.stop('managed', confirmed: false);
    await subject.stop('unmanaged', confirmed: true);
    expect(repo.stops, 0);
    await subject.stop('managed', confirmed: true);
    expect(repo.stops, 1);
    subject.dispose();
  });
  test(
    'unsupported and invalidation prohibit launch and ignore late completion',
    () async {
      final repo = Repo();
      repo.availability = const AgentAvailability(
        available: false,
        reason: 'Managed child',
        cwd: '/p',
        maxAgents: 4,
        agents: [],
      );
      final vm = AgentsViewModel(repo);
      await vm.initialize('peer', 'room');
      await vm.launch('/p', null, confirmed: true);
      expect(repo.launches, 0);
      repo.availability = const AgentAvailability(
        available: true,
        cwd: '/p',
        maxAgents: 4,
        agents: [],
      );
      await vm.refresh();
      repo.pending = Completer<ManagedAgent>();
      final start = vm.launch('/p', null, confirmed: true);
      repo.invalid.add(null);
      await Future<void>.delayed(Duration.zero);
      repo.pending!.complete(agent);
      await start;
      expect(vm.state.invalid, true);
      expect(vm.state.availability, null);
      await vm.launch('/p', null, confirmed: true);
      expect(repo.launches, 1);
      vm.dispose();
    },
  );
  test('invalid input never dispatches', () async {
    final repo = Repo();
    final subject = AgentsViewModel(repo);
    await subject.initialize('peer', 'room');
    await subject.launch('/p\ncode', null, confirmed: true);
    expect(repo.launches, 0);
    expect(subject.state.message, contains('control'));
    subject.dispose();
  });
}
