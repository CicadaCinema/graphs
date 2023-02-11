import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';

import 'graph_painter.dart';
import 'graph_theme.dart';

class StaticGraph extends StatefulWidget {
  final StaticLayoutAlgorithm layoutAlgorithm;
  final GraphThemePreferences themePreferences;
  final Duration resizeBufferDuration;

  const StaticGraph({
    Key? key,
    required this.layoutAlgorithm,
    this.themePreferences = const GraphThemePreferences(),
    this.resizeBufferDuration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<StaticGraph> createState() => _StaticGraphState();
}

class _StaticGraphState extends State<StaticGraph> {
  late RestartableTimer _redrawTimer;

  double? _previousWidth;
  double? _previousHeight;

  @override
  void initState() {
    super.initState();
    // Initially cancel the timer, so that it can only be triggered after a call
    // to [widget.layoutAlgorithm.updateLayoutParameters].
    _redrawTimer = RestartableTimer(
      widget.resizeBufferDuration,
      () {
        setState(() {
          // TODO: compute this in an isolate or a web worker, depending on platform
          widget.layoutAlgorithm.computeLayout();
        });
      },
    );
    _redrawTimer.cancel();
  }

  @override
  void dispose() {
    _redrawTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The widget has been resized.
          if (constraints.maxWidth != _previousWidth ||
              constraints.maxHeight != _previousHeight) {
            widget.layoutAlgorithm.updateLayoutParameters(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              nodeRadius: widget.themePreferences.nodeRadius,
            );
            _redrawTimer.reset();

            // Update the cached dimensions.
            _previousWidth = constraints.maxWidth;
            _previousHeight = constraints.maxHeight;
          }

          return CustomPaint(
            painter: GraphPainter(
              edgeList: widget.layoutAlgorithm.graph.edgeList,
              nodes: widget.layoutAlgorithm.nodeLayout,
              graphTheme: GraphTheme(
                defaultColorScheme: Theme.of(context).colorScheme,
                partialGraphTheme: widget.themePreferences,
              ),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
