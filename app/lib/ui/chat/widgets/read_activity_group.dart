import 'package:app/domain/session_state.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';

import 'code_viewport.dart';
import 'tool_request_card.dart';

String activityToolName(String name) =>
    name.split(RegExp(r'[.:/]|__')).last.toLowerCase();

String activityFilePath(ToolEvent tool) {
  final args = tool.args;
  if (args is! Map) return '';
  return '${args['path'] ?? args['file_path'] ?? args['file'] ?? ''}';
}

/// Consecutive reads are supporting context, not the primary change.
/// The first invocation owns the group identity as further reads arrive.
class ReadActivityGroup extends StatelessWidget {
  const ReadActivityGroup({
    super.key,
    required this.reads,
    required this.changedPaths,
  });
  final List<ToolEvent> reads;
  final Set<String> changedPaths;

  @override
  Widget build(BuildContext context) {
    final paths = reads
        .map(activityFilePath)
        .where((p) => p.isNotEmpty)
        .toSet();
    final changed = paths.intersection(changedPaths).length;
    final running = reads
        .where(
          (r) =>
              r.status == ToolEventStatus.pending ||
              r.status == ToolEventStatus.allowed,
        )
        .length;
    final failed = reads
        .where((r) => r.status == ToolEventStatus.failed)
        .length;
    return CodeViewport(
      label:
          'Read ${paths.length} ${paths.length == 1 ? 'file' : 'files'}'
          '${changed == 0 ? '' : ' · $changed also edited'}'
          '${running == 0 ? '' : ' · $running running'}'
          '${failed == 0 ? '' : ' · $failed failed'}'
          '${paths.length == 1 ? ' · ${paths.first}' : ''}',
      text: paths.join('\n'),
      copyTooltip: 'Copy read paths',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Supporting context · expand a read for its contents',
            style: context.typo.monoSmall,
          ),
          for (final read in reads)
            ToolRequestCard(key: ValueKey(read.toolCallId), tool: read),
        ],
      ),
    );
  }
}

List<Object> activityRows(List<ChatMessage> messages) {
  final rows = <Object>[];
  for (final message in messages) {
    if (message is ToolEvent &&
        {
          'read',
          'read_symbol',
          'read_enclosing',
        }.contains(activityToolName(message.tool))) {
      if (rows.isNotEmpty && rows.last is List<ToolEvent>) {
        (rows.last as List<ToolEvent>).add(message);
      } else {
        rows.add(<ToolEvent>[message]);
      }
    } else {
      rows.add(message);
    }
  }
  return rows;
}
