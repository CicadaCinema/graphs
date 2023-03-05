import 'package:graph_layout/graph_layout.dart';

void main(List<String> arguments) {
  // create a `Graph` object
  // this particular one is the graph from the NetworkX home page https://networkx.org/
  final edgeList = '''0 1
0 2
0 3
1 2
1 3
2 3
3 4
4 5
5 6
6 7
7 8
7 9
7 10
8 9
8 10
9 10''';
  final graph = Graph.fromEdgeListString(edgeList);

  // pass the graph to a layout algorithm
  final layoutAlgorithm = FruchtermanReingold(graph: graph);

  // specify the layout parameters
  layoutAlgorithm.updateLayoutParameters(
    width: 300,
    height: 400,
    nodeRadius: 10,
  );

  // compute the graph layout!
  // computing the layout for a large graph can be computationally expensive,
  // consider running this in an isolate
  layoutAlgorithm.computeLayout();

  // a layout is a mapping from each graph node to a position vector within the graph layout area
  for (final nodeLayout in layoutAlgorithm.nodeLayout.entries) {
    print(
        'the node with identifier ${nodeLayout.key.hashCode} is placed at ${nodeLayout.value}');
  }
}
