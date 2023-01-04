import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';

import 'graph_painter.dart';
import 'graph_theme.dart';

class StaticGraph extends StatefulWidget {
  final StaticLayoutAlgorithm layoutAlgorithm;
  final GraphThemePreferences themePreferences;

  const StaticGraph({
    Key? key,
    required this.layoutAlgorithm,
    this.themePreferences = const GraphThemePreferences(),
  }) : super(key: key);

  @override
  State<StaticGraph> createState() => _StaticGraphState();
}

class _StaticGraphState extends State<StaticGraph> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          widget.layoutAlgorithm.updateLayoutParameters(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            nodeRadius: widget.themePreferences.nodeRadius,
          );

          // TODO: Wait a while until the resizing operation stops, then call this potentially-expensive operation in an isolate while displaying a loading indicator.
          widget.layoutAlgorithm.computeLayout();

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
