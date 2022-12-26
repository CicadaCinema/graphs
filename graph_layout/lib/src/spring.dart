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

  /// Perform one iteration of the spring algorithm, updating [nodeLayout].
  ///
  /// Returns [true] if running one iteration does not change the position of
  /// each node by much in each axis.
  bool iterate() {
    // TODO: Make these constants named parameters with default values?

    // TODO: Tune these constants.
    const c1 = 8;
    const c2 = 0.6;
    const c3 = 1;
    const c3Wall = 0.5;
    const c4 = 0.01;

    // The threshold for a small change in node position in one axis.
    const stableThreshold = 0.001;

    // Initially assume this layout is stable.
    var isStable = true;

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
        final positionChange = forceOnThisNode.scaled(c4);
        var newPosition = position + positionChange;

        // If a node will be outside the unit square as a result of the forces
        // applied to it this iteration, randomise its position instead. The new
        // position is guaranteed to lie inside the unit square.
        if (newPosition.x >= 1 ||
            newPosition.x <= 0 ||
            newPosition.y >= 1 ||
            newPosition.y <= 0) {
          newPosition = _randomVector2();
          isStable = false;
        }

        // If the position of this node changes too much, the layout is not
        // stable.
        if (isStable &&
            max(positionChange.x.abs(), positionChange.y.abs()) >
                stableThreshold) {
          isStable = false;
        }

        return newPosition;
      });
    }

    return isStable;
  }

  /// Repeatedly run [iterate] until a stable layout is obtained.
  void iterateUntilStable() {
    while (!iterate()) {}
  }
}
