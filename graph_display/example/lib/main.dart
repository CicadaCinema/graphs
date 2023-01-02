import 'package:example/jean_node_data.dart';
import 'package:flutter/material.dart';
import 'package:graph_display/graph_display.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:http/http.dart' as http;

/// Identifiers for each of the demo graphs.
// ignore: constant_identifier_names
enum DemoGraphId { K8, jean }

/// Human-readable labels for the demo graphs.
const demoNames = {
  DemoGraphId.K8: 'Complete graph on 8 vertices',
  DemoGraphId.jean: 'Character co-occurrences in Les Misérables'
};

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var selectedGraph = DemoGraphId.jean;

  /// Returns a complete [Graph] on [nodeNumber] nodes.
  Graph _generateCompleteGraph(int nodeNumber) {
    final nodes = List<int>.generate(nodeNumber, (i) => i + 1)
        .map((i) => IntegerNode(i))
        .toList();

    final edges = <Edge>{};
    for (int i = 0; i < nodeNumber; i++) {
      for (int j = 0; j < nodeNumber; j++) {
        if (i != j) {
          edges.add(Edge(left: nodes[i], right: nodes[j]));
        }
      }
    }

    return Graph.fromEdgeList(edges);
  }

  Widget displayDemo() {
    switch (selectedGraph) {
      case DemoGraphId.K8:
        {
          return InteractiveGraph(
            graphTopology: _generateCompleteGraph(8),
            layoutAlgorithm: Eades(),
          );
        }

      case DemoGraphId.jean:
        {
          return FutureBuilder<String>(
            future: http.read(Uri.http(
              'ftp.cs.stanford.edu',
              '/pub/sgb/jean.dat',
            )),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                final edges = <Edge>{};

                // Each match corresponds to a chapter, each of which contains
                // one or more scenes.
                final matches = RegExp(r'(?<=[0-9]:).*$', multiLine: true)
                    .allMatches(snapshot.data!)
                    .map((match) => match[0]!.split(';'))
                    .expand((e) => e);

                // Iterate over each scene. Two characters are said to co-occur
                // if they appear in the same scene.
                for (final m in matches) {
                  // The characters in this scene.
                  final characters = m
                      .split(',')
                      .map((characterString) =>
                          IntegerNode(characterString.hashCode))
                      .toList();

                  // Find each pair in this group and add it as an edge. There
                  // is no need to worry about time complexity here because
                  // [characters] is small.
                  for (final char1 in characters) {
                    for (final char2 in characters) {
                      if (char1 != char2) {
                        edges.add(Edge(left: char1, right: char2));
                      }
                    }
                  }
                }
                return InteractiveGraph(
                  graphTopology: Graph.fromEdgeList(edges),
                  layoutAlgorithm: Eades(),
                  nodeRadius: 15,
                  // TODO: Create convenience fields backgroundColour, edgeColour, edgeThickness, nodeColour
                  // (similar to how nodeRadius is implemented) so that the user
                  // doesn't have to specify the entire draw... callback.
                  drawBackground: (Canvas canvas, Size size) {
                    final backgroundPaint = Paint()
                      ..color = Colors.blueGrey.shade50;
                    canvas.drawRect(
                      Rect.fromPoints(
                          Offset.zero, Offset(size.width, size.height)),
                      backgroundPaint,
                    );
                  },
                  drawEdge: (Canvas canvas, Edge edge, Vector2 leftPosition,
                      Vector2 rightPosition) {
                    final edgePaint = Paint()
                      ..strokeWidth = 0.2
                      ..color = Colors.blueGrey
                      ..style = PaintingStyle.stroke;
                    canvas.drawPath(
                        Path()
                          ..moveTo(leftPosition.x, leftPosition.y)
                          ..lineTo(rightPosition.x, rightPosition.y)
                          ..close(),
                        edgePaint);
                  },
                  drawNode: (Canvas canvas, Node node, Vector2 position) {
                    // See jean_node_data.dart for the source of this colour map.
                    final nodePaint = Paint()..color = nodeToColour[node]!;
                    final nodeOffset = Offset(position.x, position.y);
                    canvas.drawCircle(nodeOffset, 15, nodePaint);

                    // Draw the character label. See jean_node_data.dart for the
                    // source of this data.
                    final textSpan = TextSpan(
                      text: nodeToName[node]!,
                      style: const TextStyle(color: Colors.black),
                    );
                    final textPainter = TextPainter(
                      text: textSpan,
                      textDirection: TextDirection.ltr,
                    );
                    textPainter.layout();
                    textPainter.paint(
                      canvas,
                      nodeOffset - const Offset(7.5, 10),
                    );
                    // TODO: Eventually we will have to call `textPainter.dispose()` here.
                    // See https://github.com/flutter/flutter/blob/0b451b6dfd6de73ff89d89081c33d0f971db1872/packages/flutter/lib/src/painting/text_painter.dart#L171 .
                  },
                );
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error fetching graph data'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // A dropdown menu which selects the demo graph to display.
            DropdownButton(
              value: selectedGraph,
              onChanged: (value) {
                setState(() {
                  selectedGraph = value!;
                });
              },
              items: DemoGraphId.values
                  .map((demoId) => DropdownMenuItem(
                        value: demoId,
                        child: Text(demoNames[demoId]!),
                      ))
                  .toList(),
            ),
            // The graph demo itself.
            displayDemo(),
          ],
        ),
      ),
    );
  }
}
