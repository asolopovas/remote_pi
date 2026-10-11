import 'dart:async';

import 'package:app/ui/core/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CodeViewport extends StatefulWidget {
  const CodeViewport({
    super.key,
    required this.child,
    required this.text,
    this.label = 'code',
    this.headerBuilder,
  });

  final Widget child;
  final String text;
  final String label;
  final Widget Function(BuildContext context, Widget controls)? headerBuilder;

  @override
  State<CodeViewport> createState() => _CodeViewportState();
}

class _CodeViewportState extends State<CodeViewport>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  bool _wrap = false;
  bool _copied = false;
  Timer? _reset;

  @override
  bool get wantKeepAlive => _wrap || (_scroll.hasClients && _scroll.offset > 0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(updateKeepAlive);
  }

  void _toggleWrap() {
    setState(() => _wrap = !_wrap);
    updateKeepAlive();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final standalone = widget.headerBuilder == null;
    final frame = BoxDecoration(
      color: colors.codeBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.border),
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          key: const Key('code-wrap'),
          onPressed: _toggleWrap,
          icon: Icon(
            _wrap ? LucideIcons.moveHorizontal : LucideIcons.wrapText,
            size: 14,
          ),
          label: Text(_wrap ? 'Scroll' : 'Wrap'),
          style: TextButton.styleFrom(
            foregroundColor: colors.muted2,
            textStyle: context.typo.monoSmall.copyWith(fontSize: 10),
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          ),
        ),
        IconButton(
          key: const Key('code-copy'),
          tooltip: 'Copy code',
          iconSize: 14,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          padding: const EdgeInsets.all(4),
          visualDensity: VisualDensity.compact,
          onPressed: _copy,
          icon: Icon(
            _copied ? LucideIcons.check : LucideIcons.copy,
            color: _copied ? colors.success : colors.muted2,
          ),
        ),
      ],
    );
    final header =
        widget.headerBuilder?.call(context, controls) ??
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label.isEmpty ? 'code' : widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.monoSmall.copyWith(
                    color: colors.muted2,
                    fontSize: 10,
                  ),
                ),
              ),
              controls,
            ],
          ),
        );
    final padding = standalone
        ? const EdgeInsets.fromLTRB(8, 2, 8, 8)
        : const EdgeInsets.only(top: 4, bottom: 8);
    final content = _wrap
        ? Padding(padding: padding, child: widget.child)
        : Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: padding,
              child: widget.child,
            ),
          );
    return Container(
      width: double.infinity,
      margin: standalone ? const EdgeInsets.symmetric(vertical: 10) : null,
      decoration: standalone ? frame : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, content],
      ),
    );
  }
}
