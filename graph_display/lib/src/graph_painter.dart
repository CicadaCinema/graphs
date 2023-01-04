import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';

import 'graph_theme.dart';

class GraphPainter extends CustomPainter {
  final EdgeList edgeList;
  final NodeLayout nodes;

  final GraphTheme graphTheme;

  GraphPainter({
    required this.edgeList,
    required this.nodes,
    required this.graphTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    graphTheme.drawBackground(canvas, size);

    // Draw the graph edges according to the computed layout.
    for (final edge in edgeList) {
      graphTheme.drawEdge(canvas, edge, nodes[edge.left]!, nodes[edge.right]!);
    }

    // Draw each of the nodes, so that they overlap the edges.
    for (final nodeEntry in nodes.entries) {
      graphTheme.drawNode(canvas, nodeEntry.key, nodeEntry.value);
    }
  }

  // TODO: Is more fine grained logic necessary?
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
