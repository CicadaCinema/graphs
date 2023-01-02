import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'layout_algorithms.dart';

/// An implementation of the Eades layout algorithm.
class Eades extends InteractiveLayoutAlgorithm {
  // Constants used in the Eades algorithm.
  final double c1;
  final double c2;
  final double c3;
  final double c4;
  final double c5;

  Eades({
    required super.graph,
    // TODO: Tune these constants.
    this.c1 = 15.0,
    this.c2 = 150.0,
    this.c3 = 5000.0,
    this.c4 = 1.0,
    this.c5 = 0.0,
  });

  @override
  bool iterate() {
    // Initially assume this layout is stable.
    var isStable = true;

    // Nodes which are free to move.
    final unconstrainedNodes =
        graph.adjacencyList.keys.toSet().difference(constrainedNodes);

    // Calculate the forces on each node in the graph.
    for (final node in unconstrainedNodes) {
      final nodePosition = nodeLayout[node]!;
      var forceOnThisNode = Vector2.zero();

      // Iterate over every _other_ node in the graph.
      for (final otherNode
          in graph.adjacencyList.keys.where((other) => other != node)) {
        // A vector from node to otherNode.
        final thisToOther = nodeLayout[otherNode]! - nodePosition;
        final d = thisToOther.length;

        if (graph.adjacencyList[node]!.contains(otherNode)) {
          // If otherNode is adjacent to node, apply an attractive force.
          forceOnThisNode += thisToOther.normalized().scaled(c1 * log(d / c2));
        } else {
          // Otherwise, apply a repulsive force.
          forceOnThisNode -= thisToOther.normalized().scaled(c3 / pow(d, 2));
        }
      }

      // A small attractive force pulls each node to the centre.
      forceOnThisNode += (layoutCentre - nodePosition).scaled(c5);

      nodeLayout.update(node, (position) {
        final positionChange = forceOnThisNode.scaled(c4);
        final newPosition = position + positionChange;

        // Ensure no part of each drawn node is drawn outside the layout area.
        // Restricting the node position by [Vector2.random()] on each side also
        // ensures that the position of any two nodes is never clamped to the
        // same point. Otherwise, groups of nodes may get 'stuck' at a corner
        // of the layout area, even after the area is expanded.
        newPosition.clamp(
          Vector2.all(nodeRadius) + Vector2.random(),
          layoutDimensions - Vector2.all(nodeRadius) - Vector2.random(),
        );

        // If the position of this node changes too much, the layout is not
        // stable.
        isStable = isStable && positionChange.length < stableThreshold;

        return newPosition;
      });
    }

    return isStable;
  }
}
