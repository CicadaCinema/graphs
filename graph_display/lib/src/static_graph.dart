import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';

import 'graph_painter.dart';
import 'graph_theme.dart';

/// A widget providing a static, non-interactive visualisation of a graph,
/// given any [StaticLayoutAlgorithm] to compute the layout.
///
/// [layoutAlgorithm.computeLayout] is called once, when the widget is first
/// built, and a duration of [resizeBufferPeriod] after the constraints imposed
/// on the widget are changed (this typically happens when the app is resized).
///
/// This widget must be a child of `Row`, `Column`, or `Flex`.
/// For displaying a graph that the user can interact with, consider using
/// [InteractiveGraph].
class StaticGraph extends StatefulWidget {
  final StaticLayoutAlgorithm layoutAlgorithm;
  final GraphThemePreferences themePreferences;
  final Duration resizeBufferPeriod;

  const StaticGraph({
    Key? key,
    required this.layoutAlgorithm,
    this.themePreferences = const GraphThemePreferences(),
    this.resizeBufferPeriod = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<StaticGraph> createState() => _StaticGraphState();
}

class _StaticGraphState extends State<StaticGraph> {
  late RestartableTimer _redrawTimer;
  late StaticLayoutAlgorithm _algorithm = widget.layoutAlgorithm;

  double? _previousWidth;
  double? _previousHeight;

  @override
  void initState() {
    super.initState();
    // Initially cancel the timer, so that it can only be triggered after a call
    // to [widget.layoutAlgorithm.updateLayoutParameters].
    _redrawTimer = RestartableTimer(
      widget.resizeBufferPeriod,
      () async {
        compute(_computeLayout, _algorithm).then((StaticLayoutAlgorithm value) {
          setState(() {
            _algorithm = value;
          });
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
            _algorithm.updateLayoutParameters(
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
              edgeList: _algorithm.graph.edgeList,
              nodes: _algorithm.nodeLayout,
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

/// Given a static layout [algorithm], runs [algorithm.computeLayout] and returns the mutated [algorithm] object.
///
/// This function is used only in calls to [compute] from [flutter/foundation.dart], so being a little wasteful in terms of memory is OK in this case.
StaticLayoutAlgorithm _computeLayout(StaticLayoutAlgorithm algorithm) {
  algorithm.computeLayout();
  return algorithm;
}
