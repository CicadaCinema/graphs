library graph_display;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

import 'src/common.dart';

class SpringGraphDisplay extends StatefulWidget {
  final Graph graphTopology;

  final void Function(Canvas)? drawBackground;
  final void Function(Canvas, Vector2, Vector2)? drawEdge;
  final void Function(Canvas, Vector2)? drawNode;

  /// The period of time, in milliseconds, between successive iterations of the
  /// spring layout algorithm.
  final int intervalTime;

  const SpringGraphDisplay({
    Key? key,
    required this.graphTopology,
    this.intervalTime = 16,
    this.drawBackground,
    this.drawEdge,
    this.drawNode,
  }) : super(key: key);

  @override
  State<SpringGraphDisplay> createState() => _SpringGraphDisplayState();
}

class _SpringGraphDisplayState extends State<SpringGraphDisplay> {
  late final SpringSystem graphState = SpringSystem(
    adjacencyList: widget.graphTopology.adjacencyList,
  );
  final stopwatch = Stopwatch();

  /// The nodes which are currently constrained and whose position is not
  /// affected by the spring simulation.
  final _constrainedNodes = <Node>{};

  /// The node which is currently being dragged by the user.
  Node? _draggedNode;

  /// Whether the dragged node was constrained before the drag began.
  bool _draggedNodeWasConstrained = false;

  // Default methods for drawing the background, edges and nodes with theme-
  // aware colours.
  late final drawBackground = widget.drawBackground ??
      (Canvas canvas) {
        final backgroundPaint = Paint()
          ..color = Theme.of(context).colorScheme.background;
        // A unit square serves as a background.
        canvas.drawRect(
          Rect.fromPoints(Offset.zero, const Offset(1, 1)),
          backgroundPaint,
        );
      };
  late final drawEdge = widget.drawEdge ??
      (Canvas canvas, Vector2 leftPosition, Vector2 rightPosition) {
        final edgePaint = Paint()
          ..strokeWidth = 0.005
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
        canvas.drawCircle(position.toOffset(), 0.05, nodePaint);
      };

  @override
  initState() {
    super.initState();

    // Start a periodic timer which will iterate on the layout according to the
    // spring algorithm every intervalTime milliseconds.
    Timer.periodic(Duration(milliseconds: widget.intervalTime), (timer) {
      // Time how long each iteration takes and print it to the debug console.
      // TODO: Perform benchmarks, store the results in repo, then remove this code.
      stopwatch.start();
      setState(() {
        graphState.iterate(constrainedNodes: _constrainedNodes);
      });
      stopwatch.stop();
      if (kDebugMode) {
        print(stopwatch.elapsed.inMicroseconds);
      }
      stopwatch.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: FittedBox(
        child: GestureDetector(
          // If a node is tapped, toggle whether or not it is constrained.
          onTapUp: (details) {
            final panPosition = details.localPosition.toVector2();
            final closestNode = graphState.nodeLayout.closest(panPosition);
            if (panPosition.distanceTo(graphState.nodeLayout[closestNode]!) <
                0.05) {
              _constrainedNodes.toggle(closestNode);
            }
          },
          // If a node drag is started, set [_draggedNode] to the dragged node
          // and ensure it is constrained.
          onPanStart: (details) {
            final panPosition = details.localPosition.toVector2();
            final closestNode = graphState.nodeLayout.closest(panPosition);
            if (panPosition.distanceTo(graphState.nodeLayout[closestNode]!) <
                0.05) {
              _draggedNode = closestNode;
              _draggedNodeWasConstrained =
                  _constrainedNodes.contains(closestNode);
              _constrainedNodes.add(closestNode);
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
              _constrainedNodes.remove(_draggedNode);
            }
            _draggedNode = null;
          },
          child: CustomPaint(
            painter: _GraphPainter(
              edgeList: widget.graphTopology.edgeList,
              nodes: graphState.nodeLayout,
              drawBackground: drawBackground,
              drawEdge: drawEdge,
              drawNode: drawNode,
            ),
            size: const Size.square(1),
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final EdgeList edgeList;
  final NodeLayout nodes;

  final void Function(Canvas) drawBackground;
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
    drawBackground(canvas);

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
