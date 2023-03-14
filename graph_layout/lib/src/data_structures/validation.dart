import 'package:graph_layout/src/data_structures/typedefs.dart';

/// Ensures this is a valid adjacency list for an undirected graph.
///
/// Throws [FormatException] if `adjacencyList[a] contains b` XOR
/// `adjacencyList[b] contains a` is `true` for some [Node]s `a`, `b`.
void validateUndirectedAdjacencyList(AdjacencyList adjacencyList) {
  for (final adjacencyEntry in adjacencyList.entries) {
    final nodeA = adjacencyEntry.key;
    for (final nodeB in adjacencyEntry.value) {
      if (adjacencyList[nodeB] == null) {
        throw FormatException(
            '''adjacencyList[a]!.contains(b) is true, but adjacencyList[b] is null,
where a.hashCode == ${nodeA.hashCode}
and b.hashCode == ${nodeB.hashCode}''', adjacencyList);
      } else if (!adjacencyList[nodeB]!.contains(nodeA)) {
        throw FormatException(
            '''adjacencyList[a]!.contains(b) is true, but adjacencyList[b]!.contains(a) is false,
where a.hashCode == ${nodeA.hashCode}
and b.hashCode == ${nodeB.hashCode}''', adjacencyList);
      }
    }
  }
}
