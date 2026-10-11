import 'package:flutter/material.dart';

import 'package:app/ui/core/themes/themes.dart';

/// One session/tab viewport owns disclosure alignment and its single heading.
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
  _AccordionAnchorState? _pinned;
  _AccordionAnchorState? _align;
  bool _scheduled = false;
  double _extent = 0;
  double _headingHeight = 0;
  Widget? _pinnedHeader;
  EdgeInsets _headingInset = EdgeInsets.zero;
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
    _AccordionAnchorState? candidate;
    double height = 0;
    double candidateTop = -double.infinity;
    EdgeInsets inset = EdgeInsets.zero;
    for (final entry in expanded) {
      final card = _rect(entry._card);
      final header = _rect(entry._header);
      if (card == null || header == null) continue;
      if (header.top <= viewport.top + 0.5 &&
          card.bottom > viewport.top + header.height) {
        // Nested cards start later than their ancestors; ties use registration order.
        if (header.top >= candidateTop) {
          candidate = entry;
          candidateTop = header.top;
          height = header.height;
          inset = EdgeInsets.only(
            left: (header.left - viewport.left).clamp(0.0, viewport.width),
            right: (viewport.right - header.right).clamp(0.0, viewport.width),
          );
        }
      }
    }
    if (_pinned != candidate ||
        (_headingHeight - height).abs() > 0.5 ||
        !identical(_pinnedHeader, candidate?.widget.header) ||
        _headingInset != inset) {
      final previous = _pinned;
      setState(() {
        _pinned = candidate;
        _headingHeight = height;
        _pinnedHeader = candidate?.widget.header;
        _headingInset = inset;
      });
      previous?._refresh();
      candidate?._refresh();
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
        child: Stack(
          key: _bounds,
          children: [
            ClipRect(
              clipper: _HeadingClip(_headingHeight),
              child: widget.child,
            ),
            if (_pinned case final entry?)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  key: const Key('accordion-pinned-heading'),
                  color: context.colors.codeBg,
                  child: Padding(
                    padding: _headingInset,
                    child: entry.widget.header,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeadingClip extends CustomClipper<Rect> {
  const _HeadingClip(this.height);
  final double height;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, height, size.width, size.height);
  @override
  bool shouldReclip(_HeadingClip oldClipper) => height != oldClipper.height;
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

  void _refresh() {
    if (mounted) setState(() {});
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
        Visibility(
          key: _header,
          visible: _owner?._pinned != this,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: widget.header,
        ),
        if (widget.expanded) widget.body,
      ],
    );
  }
}
