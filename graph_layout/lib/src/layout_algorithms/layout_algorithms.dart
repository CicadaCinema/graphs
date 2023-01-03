import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../../graph_layout.dart';

// TODO: Consider using @protected to prevent fields of this class from being used outside its subclasses.
// See: https://api.flutter.dev/flutter/meta/protected-constant.html .
/// A generic interactive graph layout algorithm.
///
/// After creating an instance of this class, you *must* call
/// [initialiseGraph] to pass graph topology data to the algorithm, then call
/// [updateLayoutParameters] to pass the dimensions of the graph drawing area.
///
/// After, call [iterate] to execute one iteration of the algorithm, or run
/// [iterateUntilStable] to repeatedly perform iterations until the layout
/// becomes stable. Access the computed layout with [nodeLayout].
abstract class InteractiveLayoutAlgorithm {
  /// The topology of the given graph.
  final Graph graph;

  /// The computed layout of the given graph.
  final NodeLayout nodeLayout = {};

  /// The nodes unaffected by iterations of the algorithm.
  final Set<Node> constrainedNodes = {};

  /// The components of this vector correspond to the dimensions of the graph
  /// layout drawing area.
  var layoutDimensions = Vector2.all(1);

  /// The centre of the area where the graph layout is drawn.
  late var layoutCentre = layoutDimensions / 2;

  /// The threshold for a small change in node position in one axis.
  var stableThreshold = 0.0001;

  late double nodeRadius;

  InteractiveLayoutAlgorithm({required this.graph}) {
    // Initially assign random positions within the unit square.
    for (final node in graph.adjacencyList.keys) {
      nodeLayout[node] = Vector2.random();
    }
  }

  /// Update (or initialise) the graph layout area and the radius of each node.
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
    for (final node in graph.adjacencyList.keys) {
      nodeLayout[node]!.multiply(scaleFactor);
    }

    layoutDimensions = Vector2(width, height);
    layoutCentre = layoutDimensions / 2;
  }

  /// Perform one iteration of the algorithm, updating [nodeLayout].
  ///
  /// Returns `true` if running one iteration does not change the position of
  /// each node by much in each axis.
  bool iterate();

  /// Repeatedly run [iterate] until a stable layout is obtained.
  ///
  /// This method is not guaranteed to terminate; be careful when using it on
  /// complex graphs.
  void iterateUntilStable() {
    while (!iterate()) {}
  }
}
