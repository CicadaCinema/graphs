import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'layout_algorithms.dart';

class FruchtermanReingold extends InteractiveLayoutAlgorithm {
  /// The current temperature.
  ///
  /// For each iteration, the position of each node changes by a vector with
  /// magnitude at most [t].
  double t;

  final double C;

  /// The scale factor by which [t] decreases every iteration.
  final double tDecay;
  late var k = C *
      sqrt((layoutDimensions.x * layoutDimensions.y) /
          graph.adjacencyList.keys.length);

  // ignore: non_constant_identifier_names
  double _f_a(double x) => pow(x, 2) / k;

  // ignore: non_constant_identifier_names
  double _f_r(double x) => pow(k, 2) / x;

  FruchtermanReingold({
    required super.graph,
    // TODO: Tune these constants.
    this.C = 0.5,
    this.tDecay = 0.99,
    double tInitial = 300.0,
  }) : t = tInitial;

  @override
  void updateLayoutParameters({
    required double width,
    required double height,
    required double nodeRadius,
  }) {
    super.updateLayoutParameters(
      width: width,
      height: height,
      nodeRadius: nodeRadius,
    );

    // This is a constant which depends both on the layout area and the node number.
    k = C *
        sqrt((layoutDimensions.x * layoutDimensions.y) /
            graph.adjacencyList.keys.length);
  }

  @override
  bool iterate() {
    // Initially assume this layout is stable.
    var isStable = true;

    // The displacement of each node.
    final nodeDisplacement = Map.fromEntries(
        graph.adjacencyList.keys.map((node) => MapEntry(node, Vector2.zero())));

    // Calculate repulsive forces.
    for (final node in graph.adjacencyList.keys) {
      // Iterate over every _other_ node in the graph.
      for (final otherNode
          in graph.adjacencyList.keys.where((other) => other != node)) {
        final delta = nodeLayout[node]! - nodeLayout[otherNode]!;
        nodeDisplacement[node]!.add(delta.normalized() * _f_r(delta.length));
      }
    }

    // Calculate attractive forces.
    for (final edge in graph.edgeList) {
      final delta = nodeLayout[edge.left]! - nodeLayout[edge.right]!;
      nodeDisplacement[edge.left]!.sub(delta.normalized() * _f_a(delta.length));
      nodeDisplacement[edge.right]!
          .add(delta.normalized() * _f_a(delta.length));
    }

    for (final node in graph.adjacencyList.keys) {
      nodeLayout.update(node, (position) {
        final positionChange = nodeDisplacement[node]!.normalized() *
            min(nodeDisplacement[node]!.length, t);
        final newPosition = position + positionChange;

        clampNodeVector(newPosition);

        // If the position of this node changes too much, the layout is unstable.
        isStable = isStable && positionChange.length < stableThreshold;

        return newPosition;
      });
    }

    t *= tDecay;

    return isStable;
  }
}
