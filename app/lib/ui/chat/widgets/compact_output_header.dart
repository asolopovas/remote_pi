import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';

/// The disclosure target is separate from copy/wrap controls.
class CompactOutputHeader extends StatelessWidget {
  const CompactOutputHeader({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.disclosureKey,
    this.status,
    this.color,
    this.icon,
    this.controls,
    this.statusAction,
  });
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Key disclosureKey;
  final String? status;
  final Color? color;
  final IconData? icon;
  final Widget? controls;
  final Widget? statusAction;

  @override
  Widget build(BuildContext context) {
    final disclosure = Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        key: disclosureKey,
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.chevron_right,
                  size: 18,
                  color: color ?? context.colors.muted2,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.monoSmall,
                  ),
                ),
                if (status != null && statusAction == null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.4,
                    ),
                    child: Text(
                      status!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.typo.monoSmall.copyWith(
                        color: color,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!expanded && controls != null)
          Row(
            children: [
              Expanded(child: disclosure),
              controls!,
            ],
          )
        else
          disclosure,
        if (statusAction != null)
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (status != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 4),
                    Text(
                      status!,
                      style: context.typo.monoSmall.copyWith(color: color),
                    ),
                    statusAction!,
                  ],
                ),
            ],
          ),
        if (expanded && controls != null)
          Align(alignment: Alignment.centerRight, child: controls),
      ],
    );
  }
}
