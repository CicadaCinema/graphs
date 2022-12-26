library graph_display;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:graph_layout/graph_layout.dart';

import 'src/common.dart';

class SpringGraphDisplay extends StatefulWidget {
  final Graph graphTopology;

  /// The period of time, in milliseconds, between successive iterations of the
  /// spring layout algorithm.
  final int intervalTime;

  const SpringGraphDisplay({
    Key? key,
    required this.graphTopology,
    this.intervalTime = 16,
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

  final _backgroundPaint = Paint()..color = const Color(0xFF779000);
  final _edgePaint = Paint()
    ..strokeWidth = 0.005
    ..color = const Color(0xFFFF9000)
    ..style = PaintingStyle.stroke;
  final _nodePaint = Paint()..color = const Color(0xFF1190FF);

  _GraphPainter({
    required this.edgeList,
    required this.nodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // A unit square serves as a background.
    canvas.drawRect(
      Rect.fromPoints(Offset.zero, const Offset(1, 1)),
      _backgroundPaint,
    );

    // Paint the graph edges according to the computed layout.
    for (final edge in edgeList) {
      // The positions of the left node and the right node.
      final leftPosition = nodes[edge.left]!;
      final rightPosition = nodes[edge.right]!;
      canvas.drawPath(
          Path()
            ..moveTo(leftPosition.x, leftPosition.y)
            ..lineTo(rightPosition.x, rightPosition.y)
            ..close(),
          _edgePaint);
    }

    for (final node in nodes.values) {
      // TODO: Is there a simpler way to obtain an Offset from a Vector2?
      canvas.drawCircle(Offset(node.x, node.y), 0.05, _nodePaint);
    }
  }

  // TODO: Is more fine grained logic necessary?
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
