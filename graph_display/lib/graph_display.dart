library graph_display;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

import 'src/common.dart';

// TODO: Provide a description of the interactive elements of this widget.
// TODO: Prevent the dragged node from being dragged outside the layout area.
/// A widget providing an interactive visualisation of a graph, using the
/// Eades layout algorithm.
///
/// This widget must be a child of `Row`, `Column`, or `Flex`.
class EadesInteractive extends StatefulWidget {
  final Graph graphTopology;

  final void Function(Canvas, Size)? drawBackground;
  final void Function(Canvas, Vector2, Vector2)? drawEdge;
  final void Function(Canvas, Vector2)? drawNode;

  /// The period of time, in milliseconds, between successive iterations of the
  /// spring layout algorithm.
  final int intervalTime;

  const EadesInteractive({
    Key? key,
    required this.graphTopology,
    this.intervalTime = 16,
    this.drawBackground,
    this.drawEdge,
    this.drawNode,
  }) : super(key: key);

  @override
  State<EadesInteractive> createState() => _EadesInteractiveState();
}

class _EadesInteractiveState extends State<EadesInteractive> {
  late final Eades graphState = Eades(
    // The initial state of the spring system.
    adjacencyList: widget.graphTopology.adjacencyList,
    layoutWidth: layoutWidth,
    layoutHeight: layoutHeight,
  );
  final stopwatch = Stopwatch();

  /// The node which is currently being dragged by the user.
  Node? _draggedNode;

  /// Whether the dragged node was constrained before the drag began.
  bool _draggedNodeWasConstrained = false;

  late double layoutWidth;
  late double layoutHeight;

  late final Timer _iterationTimer;

  // Default methods for drawing the background, edges and nodes with theme-
  // aware colours.
  late final drawBackground = widget.drawBackground ??
      (Canvas canvas, Size size) {
        final backgroundPaint = Paint()
          ..color = Theme.of(context).colorScheme.background;
        // A unit square serves as a background.
        canvas.drawRect(
          Rect.fromPoints(Offset.zero, Offset(size.width, size.height)),
          backgroundPaint,
        );
      };
  late final drawEdge = widget.drawEdge ??
      (Canvas canvas, Vector2 leftPosition, Vector2 rightPosition) {
        final edgePaint = Paint()
          ..strokeWidth = 1
          ..color = Theme.of(context).colorScheme.primary.withAlpha(64)
          ..style = PaintingStyle.stroke;
        canvas.drawPath(
            Path()
              ..moveTo(leftPosition.x, leftPosition.y)
              ..lineTo(rightPosition.x, rightPosition.y)
              ..close(),
            edgePaint);
      };
  late final drawNode = widget.drawNode ??
      (Canvas canvas, Vector2 position) {
        final nodePaint = Paint()
          ..color = Theme.of(context).colorScheme.primary;
        canvas.drawCircle(position.toOffset(), 10, nodePaint);
      };

  @override
  initState() {
    super.initState();

    // Start a periodic timer which will iterate on the layout according to the
    // spring algorithm every intervalTime milliseconds.
    _iterationTimer =
        Timer.periodic(Duration(milliseconds: widget.intervalTime), (timer) {
      // Time how long each iteration takes and print it to the debug console.
      // TODO: Perform benchmarks, store the results in repo, then remove this code.
      stopwatch.start();
      setState(() {
        graphState.iterate();
      });
      stopwatch.stop();
      if (kDebugMode) {
        print(stopwatch.elapsed.inMicroseconds);
      }
      stopwatch.reset();
    });
  }

  @override
  void dispose() {
    _iterationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        // If a node is tapped, toggle whether or not it is constrained.
        onTapUp: (details) {
          final panPosition = details.localPosition.toVector2();
          final closestNode = graphState.nodeLayout.closest(panPosition);
          if (panPosition.distanceTo(graphState.nodeLayout[closestNode]!) <
              10) {
            graphState.constrainedNodes.toggle(closestNode);
          }
        },
        // If a node drag is started, set [_draggedNode] to the dragged node
        // and ensure it is constrained.
        onPanStart: (details) {
          final panPosition = details.localPosition.toVector2();
          final closestNode = graphState.nodeLayout.closest(panPosition);
          if (panPosition.distanceTo(graphState.nodeLayout[closestNode]!) <
              10) {
            _draggedNode = closestNode;
            _draggedNodeWasConstrained =
                !graphState.constrainedNodes.add(closestNode);
          }
        },
        // If a node is being dragged, update its position.
        onPanUpdate: (details) {
          if (_draggedNode != null) {
            graphState.nodeLayout[_draggedNode!] =
                details.localPosition.toVector2();
          }
        },
        // Reset [_draggedNode] when the drag is stopped, respecting the
        // previous constrained status of the dragged node.
        onPanEnd: (details) {
          if (!_draggedNodeWasConstrained) {
            graphState.constrainedNodes.remove(_draggedNode);
          }
          _draggedNode = null;
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            layoutWidth = constraints.maxWidth;
            layoutHeight = constraints.maxHeight;
            graphState.updateLayout(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );

            return CustomPaint(
              painter: _GraphPainter(
                edgeList: widget.graphTopology.edgeList,
                nodes: graphState.nodeLayout,
                drawBackground: drawBackground,
                drawEdge: drawEdge,
                drawNode: drawNode,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final EdgeList edgeList;
  final NodeLayout nodes;

  final void Function(Canvas, Size) drawBackground;
  final void Function(Canvas, Vector2, Vector2) drawEdge;
  final void Function(Canvas, Vector2) drawNode;

  _GraphPainter({
    required this.edgeList,
    required this.nodes,
    required this.drawBackground,
    required this.drawEdge,
    required this.drawNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    drawBackground(canvas, size);

    // Draw the graph edges according to the computed layout.
    for (final edge in edgeList) {
      drawEdge(canvas, nodes[edge.left]!, nodes[edge.right]!);
    }

    // Draw each of the nodes, so that they overlap the edges.
    for (final nodePosition in nodes.values) {
      drawNode(canvas, nodePosition);
    }
  }

  // TODO: Is more fine grained logic necessary?
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
