import 'dart:math';

import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart';

import '../../graph_layout.dart';

/// A generic static graph layout algorithm.
abstract class StaticLayoutAlgorithm {
  /// The topology of the given graph.
  final Graph graph;

  /// The computed layout of the given graph.
  final NodeLayout nodeLayout = {};

  /// The threshold for a small change in node position in one axis.
  var stableThreshold = 0.0001;

  /// The components of this vector correspond to the dimensions of the graph
  /// layout drawing area.
  var layoutDimensions = Vector2.all(1);

  /// The centre of the area where the graph layout is drawn.
  late var layoutCentre = layoutDimensions / 2;

  var nodeRadius = 0.0;

  StaticLayoutAlgorithm({
    required this.graph,
  }) {
    // Initially assign random positions within the unit square.
    for (final node in graph.adjacencyList.keys) {
      nodeLayout[node] = Vector2.random();
    }
  }

  /// Specify the graph layout area and the radius of each node.
  ///
  /// The layout algorithm must be aware of the node radius so that it does not
  /// produce a layout where some part of a node lies outside the node area
  /// boundaries.
  void updateLayoutParameters({
    required double width,
    required double height,
    required double nodeRadius,
  }) {
    stableThreshold = 0.0001 * min(width, height);
    this.nodeRadius = nodeRadius;

    // Scale node positions according to the change in layout dimensions.
    final scaleFactor = Vector2(width, height);
    scaleFactor.divide(layoutDimensions);
    for (final node in nodeLayout.keys) {
      nodeLayout[node]!.multiply(scaleFactor);
    }

    layoutDimensions = Vector2(width, height);
    layoutCentre = layoutDimensions / 2;
  }

  /// Ensure no part of each drawn node is drawn outside the layout area.
  ///
  /// Restricting the node position by [Vector2.random()] on each side also
  /// ensures that the position of any two nodes is never clamped to the
  /// same point. Otherwise, groups of nodes may get 'stuck' at a corner
  /// of the layout area, even after the area is expanded.
  @protected
  void clampNodeVector(Vector2 nodePosition) {
    nodePosition.clamp(
      Vector2.all(nodeRadius) + Vector2.random(),
      layoutDimensions - Vector2.all(nodeRadius) - Vector2.random(),
    );
  }

  void computeLayout();
}

// See: https://api.flutter.dev/flutter/meta/protected-constant.html .
/// A generic interactive graph layout algorithm.
abstract class InteractiveLayoutAlgorithm extends StaticLayoutAlgorithm {
  /// The nodes unaffected by iterations of the algorithm.
  final Set<Node> constrainedNodes = {};

  InteractiveLayoutAlgorithm({required super.graph});

  /// Perform one iteration of the algorithm, updating [nodeLayout].
  ///
  /// Returns `true` if running one iteration does not change the position of
  /// each node by much in each axis.
  bool iterate();

  /// Repeatedly run [iterate] until a stable layout is obtained.
  ///
  /// This method is not guaranteed to terminate; be careful when using it on
  /// complex graphs. Subclasses of [InteractiveLayoutAlgorithm] are expected
  /// to override this method, providing their own implementation which must
  /// always terminate.
  @override
  void computeLayout() {
    while (!iterate()) {}
  }
}
