# graph_layout

https://pub.dev/packages/graph_layout

[![pub package](https://img.shields.io/pub/v/graph_layout.svg)](https://pub.dev/packages/graph_layout)

This package implements a variety of [graph drawing](https://en.wikipedia.org/wiki/Graph_drawing) algorithms and exposes sensible primitives and classes for working with graphs.

Specify your graph's topology and parameters such as the graph drawing area and run one of the algorithms to obtain a layout - a map of coordinate assignments for each node.

This package does not depend on the Flutter API, so it does not provide any Flutter widgets or mechanisms of drawing graph layouts on the screen. If you are using Flutter, consider using [graph_display](../graph_display) for displaying graphs in your app.

## Example usage

```dart
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
  print('the node with identifier ${nodeLayout.key.hashCode} is placed at ${nodeLayout.value}');
}
```

<details>
<summary>Sample output (click to expand)</summary>

```
the node with identifier 0 is placed at [289.0693054199219,359.29193115234375]
the node with identifier 1 is placed at [289.0282287597656,389.05438232421875]
the node with identifier 2 is placed at [245.93214416503906,389.1549987792969]
the node with identifier 3 is placed at [255.86280822753906,328.6600646972656]
the node with identifier 4 is placed at [229.71585083007812,246.41404724121094]
the node with identifier 5 is placed at [190.18138122558594,171.4718017578125]
the node with identifier 6 is placed at [135.32308959960938,106.98926544189453]
the node with identifier 7 is placed at [67.12056732177734,54.19843673706055]
the node with identifier 8 is placed at [10.818044662475586,49.135826110839844]
the node with identifier 9 is placed at [47.27824020385742,10.955732345581055]
the node with identifier 10 is placed at [10.854035377502441,10.905506134033203]
```

</details>

