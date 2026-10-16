import 'package:app/domain/session_state.dart';

String activityToolName(String name) =>
    name.split(RegExp(r'[.:/]|__')).last.toLowerCase();

bool isReadActivity(ChatMessage message) =>
    message is ToolEvent &&
    {
      'read',
      'read_symbol',
      'read_enclosing',
    }.contains(activityToolName(message.tool));

String activityFilePath(ToolEvent tool) {
  final args = tool.args;
  if (args is! Map) return '';
  return '${args['path'] ?? args['file_path'] ?? args['file'] ?? ''}';
}

/// Reads are transient status, never timeline rows (including failures).
List<ChatMessage> activityRows(List<ChatMessage> messages) =>
    messages.where((message) => !isReadActivity(message)).toList();

/// Only current execution belongs in status, not an earlier completed read.
String? activeReadLabel(List<ChatMessage> messages) {
  for (final message in messages.reversed) {
    if (message is! ToolEvent) continue;
    if (!isReadActivity(message) ||
        (message.status != ToolEventStatus.pending &&
            message.status != ToolEventStatus.allowed)) {
      return null;
    }
    final path = activityFilePath(message);
    return path.isEmpty ? 'Reading…' : 'Reading $path…';
  }
  return null;
}
