import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'data_structures.dart';

class SpringSystem {
  final NodeLayout nodeLayout = {};
  final AdjacencyList adjacencyList;
  final _randomGenerator = Random();

  /// Create a random vector within the unit square.
  Vector2 _randomVector2() => Vector2(
        _randomGenerator.nextDouble(),
        _randomGenerator.nextDouble(),
      );

  SpringSystem({required this.adjacencyList}) {
    // Assign random positions initially.
    for (final node in adjacencyList.keys) {
      nodeLayout[node] = _randomVector2();
    }
  }

  void iterate() {
    const c1 = 8;
    const c2 = 0.6;
    const c3 = 1;
    const c3Wall = 0.5;
    const c4 = 0.01;

    // Calculate the forces on each node in the graph.
    for (final node in adjacencyList.keys) {
      final nodePosition = nodeLayout[node]!;
      var forceOnThisNode = Vector2.zero();

      // Iterate over every _other_ node in the graph.
      for (final otherNode
          in adjacencyList.keys.where((other) => other != node)) {
        // A vector from node to otherNode.
        final thisToOther = nodeLayout[otherNode]! - nodePosition;
        final d = thisToOther.length;

        if (adjacencyList[node]!.contains(otherNode)) {
          // If otherNode is adjacent to node, apply an attractive force.
          forceOnThisNode += thisToOther.scaled(c1 * log(d / c2));
        } else {
          // Otherwise, apply a repulsive force.
          forceOnThisNode -= thisToOther.scaled(c3 / sqrt(d));
        }
      }

      final x = nodePosition.x;
      final y = nodePosition.y;

      // Repel the walls of the unit square.
      forceOnThisNode += Vector2(0, -y).scaled(c3Wall / sqrt(y));
      forceOnThisNode += Vector2(0, 1 - y).scaled(c3Wall / sqrt(y));
      forceOnThisNode += Vector2(-x, 0).scaled(c3Wall / sqrt(x));
      forceOnThisNode += Vector2(1 - x, 0).scaled(c3Wall / sqrt(x));

      nodeLayout.update(node, (position) {
        var newPosition = position + forceOnThisNode.scaled(c4);

        // If a node will be outside the unit square as a result of the forces
        // applied to it this iteration, randomise its position instead.
        if (newPosition.x >= 1 ||
            newPosition.x <= 0 ||
            newPosition.y >= 1 ||
            newPosition.y <= 0) {
          newPosition = _randomVector2();
        }

        // The new position is guaranteed to lie inside the unit square.
        return newPosition;
      });
    }
  }
}
