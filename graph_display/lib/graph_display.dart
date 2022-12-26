library graph_display;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:graph_layout/graph_layout.dart';

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
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(),
      child: FittedBox(
        child: CustomPaint(
          painter: _GraphPainter(
            edgeList: widget.graphTopology.edgeList,
            nodes: graphState.nodeLayout,
          ),
          size: const Size.square(1),
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
