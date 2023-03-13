import 'package:vector_math/vector_math.dart';

import 'data_structures.dart';

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
