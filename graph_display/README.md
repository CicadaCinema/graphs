# graph_display

This package exposes widgets for displaying graphs in Flutter in a customisable way.

If you are not using Flutter, or you require a more specific graph widget, use [graph_layout](../graph_layout) instead to generate graph layouts, and write your own code for displaying these on the screen.

## Example usage

Construct the graph you wish to visualise.

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
```

You can then display this graph as a widget! The graph can either be interactive, allowing the users of your app to drag the nodes around to explore the graph, or static, requiring no computation once the graph layout has been generated.

```dart
InteractiveGraph(
  layoutAlgorithm: Eades(graph: graph),
);
```

```dart
StaticGraph(
  layoutAlgorithm: FruchtermanReingold(graph: graph),
)
```

## Demo

https://cicadacinema.github.io/graphs/

