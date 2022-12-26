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
  bool iterate({Set<Node> constrainedNodes = const {}}) {
    // TODO: Make these constants named parameters with default values?

    // TODO: Tune these constants.
    const c1 = 8;
    const c2 = 0.6;
    const c3 = 1;
    const c4 = 0.01;
    const c5 = 0.4;
    const c6 = 0.1;

    // The threshold for a small change in node position in one axis.
    const stableThreshold = 0.001;

    // Initially assume this layout is stable.
    var isStable = true;

    // Nodes which are free to move.
    final unconstrainedNodes =
        adjacencyList.keys.toSet().difference(constrainedNodes);

    // Calculate the forces on each node in the graph.
    for (final node in unconstrainedNodes) {
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
          forceOnThisNode += thisToOther.normalized().scaled(c1 * log(d / c2));
        } else {
          // Otherwise, apply a repulsive force.
          forceOnThisNode -= thisToOther.normalized().scaled(c3 / pow(d, 2));
        }
      }

      // A small attractive force pulls each node to the centre.
      forceOnThisNode += (Vector2.all(0.5) - nodePosition).scaled(c5);

      nodeLayout.update(node, (position) {
        final positionChange = forceOnThisNode.scaled(c4);
        final newPosition = position + positionChange;
        newPosition.clampScalar(c6, 1 - c6);

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
  void iterateUntilStable({Set<Node> constrainedNodes = const {}}) {
    while (!iterate(constrainedNodes: constrainedNodes)) {}
  }
}
