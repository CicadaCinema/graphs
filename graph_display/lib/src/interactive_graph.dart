import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

import 'common.dart';
import 'graph_painter.dart';
import 'graph_theme.dart';

/// A widget providing an interactive visualisation of a graph, given any
/// [InteractiveLayoutAlgorithm] to compute the layout.
///
/// Nodes can be dragged to move them, and tapped to freeze their position.
/// [layoutAlgorithm.iterate] is called with a period of [iterationInterval].
///
/// This widget must be a child of `Row`, `Column`, or `Flex`.
/// For displaying a graph that the user cannot interact with,
/// consider using [StaticGraph].
class InteractiveGraph extends StatefulWidget {
  final InteractiveLayoutAlgorithm layoutAlgorithm;

  /// The duration between successive iterations of the interactive layout
  /// algorithm (calls to [layoutAlgorithm.iterate]).
  final Duration iterationInterval;

  final GraphThemePreferences themePreferences;

  const InteractiveGraph({
    Key? key,
    required this.layoutAlgorithm,
    this.iterationInterval = const Duration(milliseconds: 16),
    this.themePreferences = const GraphThemePreferences(),
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

  late final Vector2 _nodeRadiusRestriction =
      Vector2.all(widget.themePreferences.nodeRadius);

  late final Timer _iterationTimer;

  @override
  initState() {
    super.initState();

    // Start a periodic timer which will iterate on the layout according to the
    // spring algorithm every intervalTime milliseconds.
    _iterationTimer = Timer.periodic(widget.iterationInterval, (timer) {
      // Time how long each iteration takes and print it to the debug console.
      // TODO: Perform benchmarks, store the results in repo, then remove this code.
      _benchmarkStopwatch.start();
      setState(() {
        widget.layoutAlgorithm.iterate();
      });
      _benchmarkStopwatch.stop();
      if (kDebugMode) {
        //print(_benchmarkStopwatch.elapsed.inMicroseconds);
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
              widget.themePreferences.nodeRadius) {
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
              widget.themePreferences.nodeRadius) {
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
              nodeRadius: widget.themePreferences.nodeRadius,
            );

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
      ),
    );
  }
}
