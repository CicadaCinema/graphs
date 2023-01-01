import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../data_structures/data_structures.dart';
import 'layout_algorithms.dart';

/// An implementation of the Eades layout algorithm.
class Eades extends InteractiveLayoutAlgorithm {
  @override
  final NodeLayout nodeLayout = {};

  @override
  final Set<Node> constrainedNodes = {};

  /// The adjacency list describing the topology of the given graph.
  late AdjacencyList adjacencyList;

  /// The vector, the components of which correspond to the dimensions of the
  /// graph layout drawing area.
  late Vector2 _layoutVector;

  /// The centre of the area where the graph layout is drawn.
  late Vector2 _layoutCentre;

  /// The threshold for a small change in node position in one axis.
  late double _stableThreshold;

  late double _nodeRadius;

  bool _isInitialised = false;

  // Constants used in the algorithm.
  final double c1;
  final double c2;
  final double c3;
  final double c4;
  final double c5;

  @override
  void initialiseGraph({required Graph graphTopology}) {
    adjacencyList = graphTopology.adjacencyList;
  }

  @override
  void updateLayoutParameters({
    required double width,
    required double height,
    required double nodeRadius,
  }) {
    _layoutVector = Vector2(width, height);
    _stableThreshold = 0.0001 * min(width, height);
    _layoutCentre = Vector2(width / 2, height / 2);
    _nodeRadius = nodeRadius;

    // If not initialised, assign random positions initially.
    if (!_isInitialised) {
      _isInitialised = true;
      for (final node in adjacencyList.keys) {
        final randomVector2 = Vector2.random();
        randomVector2.multiply(_layoutVector);
        nodeLayout[node] = randomVector2;
      }
    }

    // TODO: Reposition nodes intelligently if initialised.
  }

  Eades({
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
          Vector2.all(_nodeRadius) + Vector2.random(),
          _layoutVector - Vector2.all(_nodeRadius) - Vector2.random(),
        );

        // If the position of this node changes too much, the layout is not
        // stable.
        isStable = isStable && positionChange.length < _stableThreshold;

        return newPosition;
      });
    }

    return isStable;
  }
}
