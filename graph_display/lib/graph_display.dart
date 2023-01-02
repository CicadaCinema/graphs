library graph_display;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

import 'src/common.dart';

// TODO: Provide a description of the interactive elements of this widget.
/// A widget providing an interactive visualisation of a graph, using the
/// Eades layout algorithm.
///
/// This widget must be a child of `Row`, `Column`, or `Flex`.
class InteractiveGraph extends StatefulWidget {
  final Graph graphTopology;

  final InteractiveLayoutAlgorithm layoutAlgorithm;

  final void Function(Canvas, Size)? drawBackground;
  final void Function(Canvas, Edge, Vector2, Vector2)? drawEdge;
  final void Function(Canvas, Node, Vector2)? drawNode;

  /// The period of time, in milliseconds, between successive iterations of the
  /// spring layout algorithm.
  final int intervalTime;

  final double edgeThickness;
  final double nodeRadius;

  final Color? backgroundColour;
  final Color? edgeColour;
  final Color? nodeColour;

  const InteractiveGraph({
    Key? key,
    required this.graphTopology,
    required this.layoutAlgorithm,
    this.intervalTime = 16,
    this.edgeThickness = 1,
    this.nodeRadius = 10,
    this.backgroundColour,
    this.edgeColour,
    this.nodeColour,
    this.drawBackground,
    this.drawEdge,
    this.drawNode,
  }) : super(key: key);

  @override
  State<InteractiveGraph> createState() => _InteractiveGraphState();
}

class _InteractiveGraphState extends State<InteractiveGraph> {
  final _benchmarkStopwatch = Stopwatch();

  /// The node which is currently being dragged by the user.
  Node? _draggedNode;

  /// Whether the dragged node was constrained before the drag began.
  bool _draggedNodeWasConstrained = false;

  late Vector2 _layoutDimensions;

  late final Vector2 _nodeRadiusRestriction = Vector2.all(widget.nodeRadius);

  late final Timer _iterationTimer;

  // Default methods for drawing the background, edges and nodes with theme-
  // aware colours.
  late final _backgroundPaint = Paint()
    ..color =
        widget.backgroundColour ?? Theme.of(context).colorScheme.background;
  late final _edgePaint = Paint()
    ..strokeWidth = widget.edgeThickness
    ..color = widget.edgeColour ??
        Theme.of(context).colorScheme.primary.withOpacity(0.25)
    ..style = PaintingStyle.stroke;
  late final _nodePaint = Paint()
    ..color = widget.nodeColour ?? Theme.of(context).colorScheme.primary;

  late final drawBackground = widget.drawBackground ??
      (Canvas canvas, Size size) {
        // A unit square serves as a background.
        canvas.drawRect(
          Rect.fromPoints(Offset.zero, Offset(size.width, size.height)),
          _backgroundPaint,
        );
      };
  late final drawEdge = widget.drawEdge ??
      (Canvas canvas, Edge edge, Vector2 leftPosition, Vector2 rightPosition) {
        canvas.drawPath(
            Path()
              ..moveTo(leftPosition.x, leftPosition.y)
              ..lineTo(rightPosition.x, rightPosition.y)
              ..close(),
            _edgePaint);
      };
  late final drawNode = widget.drawNode ??
      (Canvas canvas, Node node, Vector2 position) {
        canvas.drawCircle(position.toOffset(), widget.nodeRadius, _nodePaint);
      };

  @override
  initState() {
    super.initState();

    widget.layoutAlgorithm.initialiseGraph(graphTopology: widget.graphTopology);

    // Start a periodic timer which will iterate on the layout according to the
    // spring algorithm every intervalTime milliseconds.
    _iterationTimer =
        Timer.periodic(Duration(milliseconds: widget.intervalTime), (timer) {
      // Time how long each iteration takes and print it to the debug console.
      // TODO: Perform benchmarks, store the results in repo, then remove this code.
      _benchmarkStopwatch.start();
      setState(() {
        widget.layoutAlgorithm.iterate();
      });
      _benchmarkStopwatch.stop();
      if (kDebugMode) {
        print(_benchmarkStopwatch.elapsed.inMicroseconds);
      }
      _benchmarkStopwatch.reset();
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
          final closestNode =
              widget.layoutAlgorithm.nodeLayout.closest(panPosition);
          if (panPosition
                  .distanceTo(widget.layoutAlgorithm.nodeLayout[closestNode]!) <
              widget.nodeRadius) {
            widget.layoutAlgorithm.constrainedNodes.toggle(closestNode);
          }
        },
        // If a node drag is started, set [_draggedNode] to the dragged node
        // and ensure it is constrained.
        onPanStart: (details) {
          final panPosition = details.localPosition.toVector2();
          final closestNode =
              widget.layoutAlgorithm.nodeLayout.closest(panPosition);
          if (panPosition
                  .distanceTo(widget.layoutAlgorithm.nodeLayout[closestNode]!) <
              widget.nodeRadius) {
            _draggedNode = closestNode;
            _draggedNodeWasConstrained =
                !widget.layoutAlgorithm.constrainedNodes.add(closestNode);
          }
        },
        // If a node is being dragged, update its position.
        onPanUpdate: (details) {
          if (_draggedNode != null) {
            final newPosition = details.localPosition.toVector2();
            // Prevent the dragged node from being dragged outside the layout
            // area.
            newPosition.clamp(
              _nodeRadiusRestriction,
              _layoutDimensions - _nodeRadiusRestriction,
            );
            widget.layoutAlgorithm.nodeLayout[_draggedNode!] = newPosition;
          }
        },
        // Reset [_draggedNode] when the drag is stopped, respecting the
        // previous constrained status of the dragged node.
        onPanEnd: (details) {
          if (!_draggedNodeWasConstrained) {
            widget.layoutAlgorithm.constrainedNodes.remove(_draggedNode);
          }
          _draggedNode = null;
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            _layoutDimensions = Vector2(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            widget.layoutAlgorithm.updateLayoutParameters(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              nodeRadius: widget.nodeRadius,
            );

            return CustomPaint(
              painter: _GraphPainter(
                edgeList: widget.graphTopology.edgeList,
                nodes: widget.layoutAlgorithm.nodeLayout,
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
  final void Function(Canvas, Edge, Vector2, Vector2) drawEdge;
  final void Function(Canvas, Node, Vector2) drawNode;

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
      drawEdge(canvas, edge, nodes[edge.left]!, nodes[edge.right]!);
    }

    // Draw each of the nodes, so that they overlap the edges.
    for (final nodeEntry in nodes.entries) {
      drawNode(canvas, nodeEntry.key, nodeEntry.value);
    }
  }

  // TODO: Is more fine grained logic necessary?
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
