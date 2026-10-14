import 'dart:typed_data';

import 'package:app/protocol/protocol.dart';

/// Abstract channel — testable interface over [PlainPeerChannel].
abstract class IChannel {
  Stream<ServerMessage> get serverMessages;
  Future<void> send(ClientMessage msg);
  Future<void> close();
}

/// Optional capability mixed into a channel that also speaks raw relay
/// control frames (subscribe_presence, peer_online, etc — see plano 12).
/// ConnectionManager does an `is IControlLink` cast to drive presence;
/// channels that don't implement it simply skip the subsystem.
abstract class IControlLink {
  Stream<ControlInbound> get controlFrames;
  void sendControl(Map<String, dynamic> json);
}

/// Authenticated outer-envelope scope, never decoded from the inner payload.
typedef ScopedPeerPayload = ({Uint8List bytes, String peer, String? room});

abstract class IScopedPeerTransport {
  Future<ScopedPeerPayload> receiveScoped();
}

/// Local ingress evidence for management error settlement; not a wire field.
class ScopedPeerError extends ErrorMessage {
  ScopedPeerError(ErrorMessage error, {required this.peer, required this.room})
    : super(
        inReplyTo: error.inReplyTo,
        code: error.code,
        message: error.message,
      );
  final String peer;
  final String? room;
}
