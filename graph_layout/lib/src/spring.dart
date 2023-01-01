import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'data_structures.dart';

/// An implementation of the Eades layout algorithm.
///
/// After creating an instance of this class, call [iterate] to execute one
/// iteration of the algorithm, or run [iterateUntilStable] to repeatedly
/// perform iterations until the layout becomes stable. Access the computed
/// layout with [nodeLayout].
class Eades {
  /// The computed layout of the given graph.
  final NodeLayout nodeLayout = {};

  /// The nodes unaffected by iterations of the algorithm.
  final Set<Node> constrainedNodes = {};

  /// The adjacency list describing the topology of the given graph.
  final AdjacencyList adjacencyList;

  /// The vector, the components of which correspond to the dimensions of the
  /// graph layout drawing area.
  late Vector2 _layoutVector;

  /// The centre of the area where the graph layout is drawn.
  late Vector2 _layoutCentre;

  /// The threshold for a small change in node position in one axis.
  late double _stableThreshold;

  // Constants used in the algorithm.
  // TODO: Tune these constants.
  static const c1 = 15.0;
  static const c2 = 150.0;
  static const c3 = 5000.0;
  static const c4 = 1.0;
  static const c5 = 0.0;
  static const nodeRadius = 10.0;

  // Call this when the graph layout area has been updated.
  void updateLayout({required double width, required double height}) {
    _layoutVector = Vector2(width, height);
    _stableThreshold = 0.0001 * min(width, height);
    _layoutCentre = Vector2(width / 2, height / 2);

    // TODO: Reposition nodes intelligently.
  }

  Eades({
    required this.adjacencyList,
    required layoutWidth,
    required layoutHeight,
  }) {
    updateLayout(width: layoutWidth, height: layoutHeight);

    // Assign random positions initially.
    for (final node in adjacencyList.keys) {
      final randomVector2 = Vector2.random();
      randomVector2.multiply(_layoutVector);
      nodeLayout[node] = randomVector2;
    }
  }

  /// Perform one iteration of the spring algorithm, updating [nodeLayout].
  ///
  /// Returns [true] if running one iteration does not change the position of
  /// each node by much in each axis.
  bool iterate() {
    // TODO: Make these constants named parameters with default values?

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
      forceOnThisNode += (_layoutCentre - nodePosition).scaled(c5);

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
          _layoutVector - Vector2.all(nodeRadius) - Vector2.random(),
        );

        // If the position of this node changes too much, the layout is not
        // stable.
        isStable = isStable && positionChange.length < _stableThreshold;

        return newPosition;
      });
    }

    return isStable;
  }

  /// Repeatedly run [iterate] until a stable layout is obtained.
  ///
  /// This method is not guaranteed to terminate; be careful when using it on
  /// complex graphs.
  void iterateUntilStable() {
    while (!iterate()) {}
  }
}
