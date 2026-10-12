import 'package:flutter/material.dart';

/// Aligns the original disclosure heading once per expansion in this viewport.
class AccordionViewport extends StatefulWidget {
  const AccordionViewport({
    super.key,
    required this.controller,
    required this.child,
    this.reverse = false,
  });
  final ScrollController controller;
  final Widget child;
  final bool reverse;

  @override
  State<AccordionViewport> createState() => _AccordionViewportState();
}

class _AccordionViewportState extends State<AccordionViewport> {
  final _bounds = GlobalKey();
  final _entries = <_AccordionAnchorState>{};
  _AccordionAnchorState? _align;
  bool _scheduled = false;
  double _extent = 0;
  _AccordionAnchorState? _edgeOwner;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_schedule);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _measure();
    });
  }

  Rect? _rect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _measure() {
    final viewport = _rect(_bounds);
    if (viewport == null || !widget.controller.hasClients) return;
    final expanded = _entries
        .where((e) => e.mounted && e.widget.expanded)
        .toList();
    // Only an edge disclosure that cannot reach the top receives extra space.
    if (_edgeOwner != null &&
        (!expanded.contains(_edgeOwner) ||
            (_rect(_edgeOwner!._card)?.height ?? viewport.height) >=
                viewport.height)) {
      final previousExtent = _extent;
      _edgeOwner = null;
      setState(() => _extent = 0);
      if (widget.reverse && previousExtent > 0) {
        final position = widget.controller.position;
        widget.controller.jumpTo(
          (position.pixels - previousExtent).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      }
      _schedule();
      return;
    }
    final align = _align;
    if (align != null && expanded.contains(align)) {
      final header = _rect(align._header);
      if (header != null) {
        final delta = header.top - viewport.top;
        final position = widget.controller.position;
        final desired = position.pixels + (widget.reverse ? -delta : delta);
        final shortage = widget.reverse
            ? position.minScrollExtent - desired
            : desired - position.maxScrollExtent;
        if (shortage > 0.5 && _extent < viewport.height) {
          _edgeOwner = align;
          setState(
            () => _extent = (_extent + shortage).clamp(0.0, viewport.height),
          );
          _schedule();
          return;
        }
        _align = null;
        final target = desired.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if ((target - position.pixels).abs() > 0.5) {
          widget.controller.jumpTo(target);
          _schedule();
          return;
        }
      }
    } else {
      _align = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return _AccordionScope(
      owner: this,
      extent: _extent,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _schedule();
          return false;
        },
        child: SizedBox(key: _bounds, child: widget.child),
      ),
    );
  }
}

class _AccordionScope extends InheritedWidget {
  const _AccordionScope({
    required this.owner,
    required this.extent,
    required super.child,
  });
  final _AccordionViewportState owner;
  final double extent;
  @override
  bool updateShouldNotify(_AccordionScope oldWidget) =>
      extent != oldWidget.extent;
}

/// Extra edge space is derived from this viewport, never a device pixel guess.
class AccordionEdgeSpace extends StatelessWidget {
  const AccordionEdgeSpace({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        context.dependOnInheritedWidgetOfExactType<_AccordionScope>()?.extent ??
        0,
  );
}

class AccordionAnchor extends StatefulWidget {
  const AccordionAnchor({
    super.key,
    required this.expanded,
    required this.header,
    required this.body,
  });
  final bool expanded;
  final Widget header;
  final Widget body;
  @override
  State<AccordionAnchor> createState() => _AccordionAnchorState();
}

class _AccordionAnchorState extends State<AccordionAnchor> {
  final _card = GlobalKey();
  final _header = GlobalKey();
  _AccordionViewportState? _owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = context
        .dependOnInheritedWidgetOfExactType<_AccordionScope>()
        ?.owner;
    if (_owner != owner) {
      _owner?._entries.remove(this);
      _owner = owner;
      owner?._entries.add(this);
    }
    owner?._schedule();
  }

  @override
  void didUpdateWidget(AccordionAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.expanded && widget.expanded) _owner?._align = this;
    _owner?._schedule();
  }

  @override
  void dispose() {
    _owner?._entries.remove(this);
    _owner?._schedule();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _owner?._schedule();
    return Column(
      key: _card,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(key: _header, child: widget.header),
        if (widget.expanded) widget.body,
      ],
    );
  }
}
