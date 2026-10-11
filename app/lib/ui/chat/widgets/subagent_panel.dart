import 'dart:convert';

import 'package:app/domain/session_state.dart';
import 'package:app/ui/chat/widgets/agent_markdown.dart';
import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SubagentInvocation {
  const SubagentInvocation({
    required this.tool,
    required this.name,
    required this.task,
  });

  final ToolEvent tool;
  final String name;
  final String task;

  static SubagentInvocation? fromTool(ToolEvent tool) {
    if (!RegExp(
      r'(^|[.:/]|__)subagent$',
      caseSensitive: false,
    ).hasMatch(tool.tool)) {
      return null;
    }
    final args = tool.args;
    if (args is! Map || args['action'] != null) return null;
    final agent = args['agent'];
    final task = args['task'];
    if (agent is String && task is String) {
      return SubagentInvocation(tool: tool, name: agent, task: task);
    }
    final workflow = args['workflow'];
    if (workflow == null || workflow == false) return null;
    final parameters = args['args'];
    final tasks = parameters is Map ? parameters['tasks'] : null;
    final labels = <String>[];
    if (tasks is Iterable) {
      for (final child in tasks) {
        if (child is! Map) continue;
        final label = child['label'] ?? child['task'] ?? child['agent'];
        if (label is String && label.isNotEmpty) labels.add(label);
      }
    }
    return SubagentInvocation(
      tool: tool,
      name: workflow is String ? workflow : 'Workflow',
      task: labels.isEmpty ? 'Subagent workflow' : labels.join('\n'),
    );
  }

  String get output {
    final result = tool.result;
    if (result == null) return '';
    return result is String
        ? result
        : const JsonEncoder.withIndent('  ').convert(result);
  }

  bool get detached =>
      RegExp(r'^Async:|\bDetached\.', multiLine: true).hasMatch(output);

  String get status => switch (tool.status) {
    ToolEventStatus.pending || ToolEventStatus.allowed => 'Running call',
    ToolEventStatus.completed => detached ? 'Launched' : 'Done',
    ToolEventStatus.failed => 'Failed',
    ToolEventStatus.denied => 'Denied',
    ToolEventStatus.expired => 'Expired',
  };

  Color statusColor(AppColors colors) => switch (tool.status) {
    ToolEventStatus.pending || ToolEventStatus.allowed => colors.working,
    ToolEventStatus.completed => detached ? colors.working : colors.success,
    ToolEventStatus.failed => colors.error,
    ToolEventStatus.denied || ToolEventStatus.expired => colors.muted2,
  };
}

class SubagentPanel extends StatelessWidget {
  const SubagentPanel({
    super.key,
    required this.invocations,
    required this.collapsed,
    required this.onCollapsedChanged,
    this.onClose,
  });

  final List<SubagentInvocation> invocations;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: ListView.separated(
        key: const PageStorageKey('subagent-panel'),
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        itemCount: invocations.length + 1,
        separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    'Subagents · ${invocations.length}',
                    style: context.typo.monoSmall.copyWith(
                      color: colors.muted2,
                      fontSize: 10,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onCollapsedChanged(!collapsed),
                  style: TextButton.styleFrom(
                    textStyle: context.typo.monoSmall.copyWith(fontSize: 10),
                    foregroundColor: colors.muted2,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(collapsed ? 'Expand all' : 'Collapse all'),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Close subagents',
                    onPressed: onClose,
                    icon: Icon(LucideIcons.x, size: 16, color: colors.muted2),
                  ),
              ],
            );
          }
          final invocation = invocations[invocations.length - index];
          return _SubagentCard(
            key: ValueKey(invocation.tool.id),
            invocation: invocation,
            collapsed: collapsed,
          );
        },
        findItemIndexCallback: (key) {
          if (key is! ValueKey<String>) return null;
          final index = invocations.indexWhere((i) => i.tool.id == key.value);
          return index < 0 ? null : invocations.length - index;
        },
      ),
    );
  }
}

class _SubagentCard extends StatefulWidget {
  const _SubagentCard({
    super.key,
    required this.invocation,
    required this.collapsed,
  });

  final SubagentInvocation invocation;
  final bool collapsed;

  @override
  State<_SubagentCard> createState() => _SubagentCardState();
}

class _SubagentCardState extends State<_SubagentCard> {
  bool? _expanded;

  @override
  void didUpdateWidget(_SubagentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed != widget.collapsed) _expanded = null;
  }

  @override
  Widget build(BuildContext context) {
    final invocation = widget.invocation;
    final colors = context.colors;
    final expanded = _expanded ?? !widget.collapsed;
    final color = invocation.statusColor(colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: InkWell(
            onTap: () => setState(() => _expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 12,
                    color: colors.muted2,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                invocation.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.typo.sansBody.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              invocation.status,
                              style: context.typo.monoSmall.copyWith(
                                color: color,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          invocation.task
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typo.monoSmall.copyWith(
                            color: colors.muted2,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(invocation.task, style: context.typo.sansBody),
                if (invocation.detached) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Launched in the background. Live child progress is not sent by this connection.',
                    style: context.typo.monoSmall.copyWith(
                      color: colors.muted2,
                    ),
                  ),
                ],
                if (invocation.tool.error?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    invocation.tool.error!,
                    style: context.typo.mono.copyWith(color: colors.error),
                  ),
                ],
                if (invocation.output.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  AgentMarkdown(invocation.output, selectable: true),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
