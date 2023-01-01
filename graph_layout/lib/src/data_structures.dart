import 'dart:math';

import 'package:vector_math/vector_math.dart';
import 'package:quiver/core.dart';

/// A node of a graph.
///
/// Concrete classes which implement [Node] **must** override [hashCode] and
/// [==] such that references to the same node can be identified.
// TODO: Wait until @mustBeOverridden lands in package:meta 1.9.0 and use it here - see https://github.com/dart-lang/sdk/commit/72805251171580d5f6528eab53b3ea3458dc0966
abstract class Node {
  @override
  int get hashCode;

  @override
  bool operator ==(Object other);
}

/// An implementation of [Node] where the nodes are identified by their integer
/// [id].
class IntegerNode extends Node {
  final int id;

  IntegerNode(this.id);

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => other is IntegerNode && id == other.id;
}

// TODO: Make a class for representing a directed edge - perhaps these could share the same superclass.
/// An _undirected_ edge of a graph.
class Edge {
  final Node left;
  final Node right;

  Edge({
    required this.left,
    required this.right,
  });

  @override
  int get hashCode => hash2(
        // Ensure Edge(a,b) and Edge(b,a) have the same hashCode.
        min(left.hashCode, right.hashCode),
        max(left.hashCode, right.hashCode),
      );

  @override
  bool operator ==(Object other) =>
      other is Edge &&
      ((left == other.left && right == other.right) ||
          (left == other.right && right == other.left));
}

AdjacencyList _unmodifiableAdjacencyList(AdjacencyList adjacencyList) =>
    Map.unmodifiable(adjacencyList
        .map((key, value) => MapEntry(key, Set.unmodifiable(value))));

EdgeList _unmodifiableEdgeList(EdgeList edgeList) => Set.unmodifiable(edgeList);

/// The topology of a graph.
///
/// Use the various members of this class to access different representations
/// of the topology. After initialisation, the members are unmodifiable so as to
/// ensure that the topology information is consistent across representations.
class Graph {
  /// An [adjacency list](https://en.wikipedia.org/wiki/Adjacency_list)
  /// representation of the graph's topology.
  late final AdjacencyList adjacencyList;

  /// An [edge list](https://en.wikipedia.org/wiki/Edge_list) representation of
  /// the graph's topology.
  late final EdgeList edgeList;

  // TODO: Improve the readability of the two non-factory constructors.
  // TODO: Ensure that the factory constructors are implemented correctly.
  // TODO: Characterise the running times (in big-O notation ideally) of the constructors and document them - benchmark this??
  /// Create a [Graph] using its adjacency list.
  Graph.fromAdjacencyList(AdjacencyList adjacencyList) {
    // TODO: Assert that this is a valid adjacency list? - ie adjacencyList[a] contains b <=> adjacencyList[b] contains a
    this.adjacencyList = _unmodifiableAdjacencyList(adjacencyList);

    // Populate this.edgeList by iterating over all the members of the Set
    // adjacencyList.values . Note that this means we see each edge twice, but
    // this is OK because edges does not allow duplicates.
    final edges = <Edge>{};
    for (final adjacencyEntry in adjacencyList.entries) {
      edges.addAll(adjacencyEntry.value.map(
          (rightNode) => Edge(left: adjacencyEntry.key, right: rightNode)));
    }
    edgeList = _unmodifiableEdgeList(edges);
  }

  /// Create a [Graph] using a [String] format of its adjacency list.
  ///
  /// The accepted format is similar to the [NetworkX adjacency list
  /// format](https://networkx.org/documentation/stable/reference/readwrite/adjlist.html#format).
  /// Here, comments or any other arbitrary data is not allowed and will result
  /// in a [FormatException].
  factory Graph.fromAdjacencyListString(String adjacencyListString) {
    final AdjacencyList adjacencyList = {};

    for (final line in adjacencyListString.split(RegExp(r'\r?\n'))) {
      final nodes = line.split(' ');

      // Allowing only one (source) node in an adjacency list line may be
      // convenient in some cases.
      if (nodes.isEmpty) {
        throw FormatException(
            'An adjacency list cannot contain an empty line', line);
      }

      final sourceNode = IntegerNode(int.parse(nodes.first));
      final targetNodes = nodes
          .skip(1)
          .map((stringId) => IntegerNode(int.parse(stringId)))
          .toSet();
      adjacencyList[sourceNode] = targetNodes;
    }

    return Graph.fromAdjacencyList(adjacencyList);
  }

  /// Create a [Graph] using its edge list.
  Graph.fromEdgeList(EdgeList edgeList) {
    // TODO: assert that this is a valid edge list? - ie no edge loops are present
    this.edgeList = _unmodifiableEdgeList(edgeList);

    // Populate this.adjacencyList by adding data to adjacencies[edge.left] and
    // adjacencies[edge.right], for every edge.
    final adjacencies = <Node, Set<Node>>{};
    for (final edge in edgeList) {
      if (adjacencies.containsKey(edge.left)) {
        adjacencies[edge.left]!.add(edge.right);
      } else {
        adjacencies[edge.left] = {edge.right};
      }

      if (adjacencies.containsKey(edge.right)) {
        adjacencies[edge.right]!.add(edge.left);
      } else {
        adjacencies[edge.right] = {edge.left};
      }
    }

    adjacencyList = _unmodifiableAdjacencyList(adjacencies);
  }

  /// Create a [Graph] using a [String] format of its edge list.
  ///
  /// The accepted format is similar to the [NetworkX edge list
  /// format](https://networkx.org/documentation/stable/reference/readwrite/edgelist.html#format).
  /// Here, comments or any other arbitrary data is not allowed and will result
  /// in a [FormatException].
  factory Graph.fromEdgeListString(String edgeListString) {
    final EdgeList edgeList = {};

    for (final line in edgeListString.split(RegExp(r'\r?\n'))) {
      final nodes = line.split(' ');

      if (nodes.length != 2) {
        throw FormatException(
            'Each line of an edge list must contain exactly two nodes.', line);
      }

      edgeList.add(Edge(
        left: IntegerNode(int.parse(nodes[0])),
        right: IntegerNode(int.parse(nodes[1])),
      ));
    }

    return Graph.fromEdgeList(edgeList);
  }
}

/// A description of the topology of a graph.
///
/// Maps from each [Node] in the graph to the [Set] of [Node]s adjacent to it.
///
/// <https://en.wikipedia.org/wiki/Adjacency_list>
typedef AdjacencyList = Map<Node, Set<Node>>;

/// A description of the topology of a graph.
///
/// Lists each [Edge] of the graph.
///
/// <https://en.wikipedia.org/wiki/Edge_list>
typedef EdgeList = Set<Edge>;

/// A description of the layout of a graph.
///
/// Maps from each [Node] in the graph to the [Vector2] position of this node.
/// Typically, this [Vector2] should lie in the unit square, so both [Vector2.x]
/// and [Vector2.y] will be between 0 and 1.
typedef NodeLayout = Map<Node, Vector2>;
