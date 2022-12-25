import 'package:flutter/material.dart';
import 'package:graph_display/graph_display.dart';
import 'package:graph_layout/graph_layout.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final Graph graph;

  @override
  void initState() {
    super.initState();

    // Create a complete graph on nodeCount nodes.
    const nodeCount = 8;

    final nodes = List<int>.generate(nodeCount, (i) => i + 1)
        .map((i) => IntegerNode(i))
        .toList();

    final edges = <Edge>{};
    for (int i = 0; i < nodeCount; i++) {
      for (int j = 0; j < nodeCount; j++) {
        if (i != j) {
          edges.add(Edge(left: nodes[i], right: nodes[j]));
        }
      }
    }

    graph = Graph.fromEdgeList(edges);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SpringGraphDisplay(
          graphTopology: graph,
        ),
      ),
    );
  }
}
