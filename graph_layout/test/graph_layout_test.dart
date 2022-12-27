import 'package:graph_layout/graph_layout.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

void main() {
  group('Data structures', () {
    late IntegerNode a;
    late IntegerNode b;
    late IntegerNode c;
    late IntegerNode d;

    late Edge aToC;
    late Edge cToA;
    late Edge aToC_;
    late Edge cToA_;
    late Edge aToD;

    setUp(() {
      a = IntegerNode(1);
      b = IntegerNode(1);
      c = IntegerNode(42);
      d = IntegerNode(43);

      aToC = Edge(left: a, right: c);
      cToA = Edge(left: c, right: a);
      aToC_ = Edge(left: a, right: c);
      cToA_ = Edge(left: c, right: a);
      aToD = Edge(left: a, right: d);
    });

    test('IntegerNode equality', () {
      // Two representations of the same node.
      expect(a == a, isTrue);
      expect(a.hashCode == a.hashCode, isTrue);
      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);

      // These are different nodes.
      expect(a == c, isFalse);
      expect(a.hashCode == c.hashCode, isFalse);
    });

    test('Edge equality', () {
      // Do not test self loops.

      // All four objects represent the same edge.
      expect(aToC == aToC, isTrue);
      expect(aToC.hashCode == aToC.hashCode, isTrue);
      expect(aToC == cToA, isTrue);
      expect(aToC.hashCode == cToA.hashCode, isTrue);
      expect(aToC_ == cToA_, isTrue);
      expect(aToC_.hashCode == cToA_.hashCode, isTrue);
      expect(aToC == aToC_, isTrue);
      expect(aToC.hashCode == aToC_.hashCode, isTrue);

      // These are different edges.
      expect(aToC == aToD, isFalse);
      expect(aToC.hashCode == aToD.hashCode, isFalse);
    });

    test('Adjacency list from edge list', () {
      // The S2 star graph.
      final s2fromEdgeList = Graph.fromEdgeList({
        Edge(left: a, right: c),
        Edge(left: a, right: d),
      });

      // Expect:
      // a -> {c, d}
      // c -> {a}
      // d -> {a}
      expect(s2fromEdgeList.adjacencyList.keys.length == 3, isTrue);
      expect(
        SetEquality().equals(s2fromEdgeList.adjacencyList[a], {c, d}),
        isTrue,
      );
      expect(
        SetEquality().equals(s2fromEdgeList.adjacencyList[c], {a}),
        isTrue,
      );
      expect(
        SetEquality().equals(s2fromEdgeList.adjacencyList[d], {a}),
        isTrue,
      );
    });

    test('Graph from empty edge list', () {
      final graphFromEmptyEdgeList = Graph.fromEdgeList({});
      expect(graphFromEmptyEdgeList.edgeList, isEmpty);
      expect(graphFromEmptyEdgeList.adjacencyList, isEmpty);
    });

    test('Edge list from adjacency list', () {
      // The S2 star graph.
      final s2fromAdjacencyList = Graph.fromAdjacencyList({
        a: {c, d},
        c: {a},
        d: {a},
      });

      // Expect:
      // Edge(left: a, right: c)
      // Edge(left: a, right: d)
      expect(s2fromAdjacencyList.edgeList.length == 2, isTrue);
      expect(
        s2fromAdjacencyList.edgeList.toList()[0] == Edge(left: a, right: c),
        isTrue,
      );
      expect(
        s2fromAdjacencyList.edgeList.toList()[1] == Edge(left: a, right: d),
        isTrue,
      );
    });

    test('Graph from empty adjacency list', () {
      final graphFromEmptyAdjacencyList = Graph.fromAdjacencyList({});
      expect(graphFromEmptyAdjacencyList.edgeList, isEmpty);
      expect(graphFromEmptyAdjacencyList.adjacencyList, isEmpty);
    });
  });
}
