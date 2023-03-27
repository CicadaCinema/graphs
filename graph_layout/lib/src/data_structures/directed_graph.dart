import 'package:quiver/core.dart';

import 'data_structures.dart';
import 'typedefs.dart';
import 'unmodifiable_helpers.dart';

/// A directed edge of a graph.
class DirectedEdge {
  final Node source;
  final Node target;

  DirectedEdge({
    required this.source,
    required this.target,
  });

  @override
  int get hashCode => hash2(
        source.hashCode,
        target.hashCode,
      );

  @override
  bool operator ==(Object other) =>
      other is DirectedEdge && source == other.source && target == other.target;
}

/// The topology of a directed graph.
class DirectedGraph {
  /// An [adjacency list](https://en.wikipedia.org/wiki/Adjacency_list)
  /// representation of the directed graph's topology.
  late final AdjacencyList adjacencyList;

  /// An [edge list](https://en.wikipedia.org/wiki/Edge_list) representation of
  /// the directed graph's topology.
  late final DirectedEdgeList edgeList;

  DirectedGraph.fromAdjacencyList(
    AdjacencyList adjacencyList,
  ) {
    this.adjacencyList = unmodifiableAdjacencyList(adjacencyList);

    final edges = <DirectedEdge>{};
    for (final adjacencyEntry in adjacencyList.entries) {
      edges.addAll(adjacencyEntry.value.map((targetNode) =>
          DirectedEdge(source: adjacencyEntry.key, target: targetNode)));
    }
    edgeList = Set.unmodifiable(edges);
  }

  DirectedGraph.fromEdgeList(DirectedEdgeList edgeList) {
    this.edgeList = Set.unmodifiable(edgeList);

    final adjacencies = <Node, Set<Node>>{};
    for (final edge in edgeList) {
      if (adjacencies.containsKey(edge.source)) {
        adjacencies[edge.source]!.add(edge.target);
      } else {
        adjacencies[edge.source] = {edge.target};
      }
    }

    adjacencyList = unmodifiableAdjacencyList(adjacencies);
  }
}
