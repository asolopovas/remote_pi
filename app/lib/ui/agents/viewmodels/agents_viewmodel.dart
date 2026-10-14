import 'dart:async';
import 'package:app/domain/contracts/agent_repository.dart';
import 'package:app/ui/core/viewmodel/viewmodel.dart';
import '../states/agents_state.dart';

class AgentsViewModel extends ViewModel<AgentsViewState> {
  AgentsViewModel(this._repo) : super(const AgentsViewState()) {
    _subscription = _repo.invalidations.listen((_) {
      if (!_disposed) {
        emit(
          const AgentsViewState(
            invalid: true,
            message:
                'Host disconnected or session changed. Return home and select it again.',
          ),
        );
      }
    });
  }
  final AgentRepository _repo;
  late final StreamSubscription<void> _subscription;
  bool _disposed = false, _started = false;
  Future<void> initialize(String peer, String room) async {
    if (_started) return;
    _started = true;
    await _run(() async {
      await _repo.bind(peer, room);
      return _repo.list();
    }, reconciles: true);
  }

  Future<void> refresh() async {
    if (state.busy || state.invalid) return;
    _repo.refreshDiscovery();
    await _run(_repo.list, reconciles: true);
  }

  Future<void> launch(
    String cwd,
    String? name, {
    required bool confirmed,
  }) async {
    if (!confirmed ||
        state.busy ||
        state.invalid ||
        state.needsReconciliation ||
        state.availability?.available != true) {
      return;
    }
    final error = validateAgentInput(cwd, name);
    if (error != null) {
      emit(AgentsViewState(availability: state.availability, message: error));
      return;
    }
    final old = state.availability!;
    await _run(
      () async {
        final agent = await _repo.launch(cwd, name);
        return AgentAvailability(
          available: old.available,
          reason: old.reason,
          cwd: old.cwd,
          maxAgents: old.maxAgents,
          agents: List.unmodifiable([
            ...old.agents.where((a) => a.agentId != agent.agentId),
            agent,
          ]),
        );
      },
      message:
          'Agent created. Waiting for room discovery: return home and open its actual session when online.',
    );
  }

  Future<void> stop(String id, {required bool confirmed}) async {
    if (!confirmed || state.busy || state.invalid) return;
    final old = state.availability;
    if (old == null ||
        !old.agents.any(
          (a) =>
              a.agentId == id &&
              (a.state == 'running' ||
                  a.state == 'starting' ||
                  a.state == 'failed'),
        )) {
      return;
    }
    await _run(() async {
      final agent = await _repo.stop(id);
      return AgentAvailability(
        available: old.available,
        reason: old.reason,
        cwd: old.cwd,
        maxAgents: old.maxAgents,
        agents: List.unmodifiable(
          old.agents.map((a) => a.agentId == agent.agentId ? agent : a),
        ),
      );
    });
  }

  Future<void> _run(
    Future<AgentAvailability> Function() operation, {
    String? message,
    bool reconciles = false,
  }) async {
    final wasUncertain = state.needsReconciliation;
    final previous = state.availability;
    emit(
      AgentsViewState(
        busy: true,
        availability: previous,
        needsReconciliation: wasUncertain,
      ),
    );
    try {
      final result = await operation();
      if (!_disposed && !state.invalid) {
        emit(
          AgentsViewState(
            availability: result,
            message: message,
            needsReconciliation: reconciles ? false : wasUncertain,
          ),
        );
      }
    } on AgentFailure catch (error) {
      if (!_disposed && !state.invalid) {
        emit(
          AgentsViewState(
            availability: previous,
            message: error.message,
            needsReconciliation: wasUncertain || error.outcomeUnknown,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    _repo.dispose();
    super.dispose();
  }
}
