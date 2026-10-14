import 'repository.dart';

class ManagedAgent {
  const ManagedAgent({
    required this.agentId,
    required this.name,
    required this.cwd,
    required this.roomId,
    required this.state,
    this.error,
  });
  final String agentId, name, cwd, roomId, state;
  final String? error;
}

class AgentAvailability {
  const AgentAvailability({
    required this.available,
    this.launcherId,
    this.reason,
    required this.cwd,
    required this.maxAgents,
    required this.agents,
  });
  final bool available;
  final String? launcherId;
  final String? reason;
  final String cwd;
  final int maxAgents;
  final List<ManagedAgent> agents;
}

class AgentFailure implements Exception {
  const AgentFailure(this.message, {this.outcomeUnknown = false});
  final String message;
  final bool outcomeUnknown;
}

abstract class AgentRepository extends Repository {
  Future<void> bind(String peer, String room);
  Stream<void> get invalidations;

  /// Settles any uncertain mutation using its original idempotency key before
  /// returning a fresh list. An empty snapshot alone is not reconciliation.
  Future<AgentAvailability> list();
  Future<ManagedAgent> launch(String cwd, String? name);
  Future<ManagedAgent> stop(String agentId);
  void refreshDiscovery();
}

String? validateAgentInput(String cwd, String? name) {
  final controls = RegExp(r'[\x00-\x1f\x7f-\x9f]');
  if (cwd.trim().isEmpty || cwd.length > 4096 || controls.hasMatch(cwd)) {
    return 'Enter an existing directory (up to 4096 characters, no control characters).';
  }
  if (name != null &&
      (name.trim().isEmpty || name.length > 80 || controls.hasMatch(name))) {
    return 'Name must be 1–80 characters, not blank, with no control characters.';
  }
  return null;
}
