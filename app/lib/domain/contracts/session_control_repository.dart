import 'repository.dart';

class SessionStopCapability {
  const SessionStopCapability({
    required this.peer,
    required this.room,
    required this.canStop,
    this.token,
    this.reason,
  });
  final String peer, room;
  final bool canStop;
  final String? token, reason;
}

enum SessionStopOutcome { requested, stopped }

class SessionControlFailure implements Exception {
  const SessionControlFailure(this.message, {this.outcomeUnknown = false});
  final String message;
  final bool outcomeUnknown;
}

/// Tokens and confirmations are ephemeral, exact-session scoped, never replayed.
abstract class SessionControlRepository extends Repository {
  Future<SessionStopCapability> inspect(String peer, String room);
  Future<SessionStopOutcome> stop(SessionStopCapability capability);
}
