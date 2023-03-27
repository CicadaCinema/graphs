import 'typedefs.dart';

AdjacencyList unmodifiableAdjacencyList(AdjacencyList adjacencyList) =>
    Map.unmodifiable(adjacencyList
        .map((key, value) => MapEntry(key, Set.unmodifiable(value))));
