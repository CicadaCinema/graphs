import 'package:graph_layout/graph_layout.dart';
import 'package:test/test.dart';

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
      expect(a.hashCode, equals(a.hashCode));
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));

      // These are different nodes.
      expect(a == c, isFalse);
      expect(a.hashCode, isNot(equals(c.hashCode)));
    });

    test('Edge equality', () {
      // Do not test self loops.

      // All four objects represent the same edge.
      expect(aToC == aToC, isTrue);
      expect(aToC.hashCode, equals(aToC.hashCode));
      expect(aToC == cToA, isTrue);
      expect(aToC.hashCode, equals(cToA.hashCode));
      expect(aToC_ == cToA_, isTrue);
      expect(aToC_.hashCode, equals(cToA_.hashCode));
      expect(aToC == aToC_, isTrue);
      expect(aToC.hashCode, equals(aToC_.hashCode));

      // These are different edges.
      expect(aToC == aToD, isFalse);
      expect(aToC.hashCode, isNot(equals(aToD.hashCode)));
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
      expect(s2fromEdgeList.adjacencyList.keys.length, equals(3));
      expect(s2fromEdgeList.adjacencyList[a], equals({c, d}));
      expect(s2fromEdgeList.adjacencyList[c], equals({a}));
      expect(s2fromEdgeList.adjacencyList[d], equals({a}));
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
      expect(s2fromAdjacencyList.edgeList.length, equals(2));
      expect(
        s2fromAdjacencyList.edgeList.toList(),
        contains(Edge(left: a, right: c)),
      );
      expect(
        s2fromAdjacencyList.edgeList.toList(),
        contains(Edge(left: a, right: d)),
      );
    });

    test('Graph from empty adjacency list', () {
      final graphFromEmptyAdjacencyList = Graph.fromAdjacencyList({});
      expect(graphFromEmptyAdjacencyList.edgeList, isEmpty);
      expect(graphFromEmptyAdjacencyList.adjacencyList, isEmpty);
    });

    // https://en.wikipedia.org/wiki/Diamond_graph
    void expectDiamondGraph(Graph graph, Node A, Node B, Node C, Node D) {
      expect(graph.edgeList.length, equals(5));
      expect(graph.edgeList, contains(Edge(left: A, right: B)));
      expect(graph.edgeList, contains(Edge(left: A, right: C)));
      expect(graph.edgeList, contains(Edge(left: B, right: C)));
      expect(graph.edgeList, contains(Edge(left: D, right: B)));
      expect(graph.edgeList, contains(Edge(left: D, right: C)));

      expect(graph.adjacencyList.length, equals(4));
      expect(graph.adjacencyList[A], equals({B, C}));
      expect(graph.adjacencyList[B], equals({A, C, D}));
      expect(graph.adjacencyList[C], equals({A, B, D}));
      expect(graph.adjacencyList[D], equals({B, C}));
    }

    test('Diamond graph from edge list string', () {
      final diamondGraph = Graph.fromEdgeListString('''11 22
11 33
22 33
44 22
44 33''');
      expectDiamondGraph(
        diamondGraph,
        IntegerNode(11),
        IntegerNode(22),
        IntegerNode(33),
        IntegerNode(44),
      );
    });

    test('Diamond graph from adjacency list string', () {
      final diamondGraph = Graph.fromAdjacencyListString('''11 22 33
22 11 33 44
33 11 22 44
44 22 33''');
      expectDiamondGraph(
        diamondGraph,
        IntegerNode(11),
        IntegerNode(22),
        IntegerNode(33),
        IntegerNode(44),
      );
    });
  });
}
