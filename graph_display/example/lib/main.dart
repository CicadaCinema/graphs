import 'package:example/jean_node_data.dart';
import 'package:flutter/material.dart';
import 'package:graph_display/graph_display.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart' hide Colors;

const _demoNames = [
  'Complete graph on 8 vertices, Eades algorithm',
  'Complete graph on 8 vertices, Fruchterman-Reingold algorithm',
  'Character co-occurrences in Les Misérables, Eades algorithm',
  'Character co-occurrences in Les Misérables, Fruchterman-Reingold algorithm',
];

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

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  var _selectedDemoIndex = 0;

  Widget _displayDemo() {
    switch (_selectedDemoIndex) {
      case 0:
        return InteractiveGraph(
          layoutAlgorithm: Eades(
            graph: _generateCompleteGraph(8),
          ),
        );
      case 1:
        return StaticGraph(
          layoutAlgorithm: FruchtermanReingold(
            graph: _generateCompleteGraph(8),
          ),
        );

      case 2:
      case 3:
        return FutureBuilder<String>(
          future: DefaultAssetBundle.of(context).loadString('assets/jean.dat'),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
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
              final theme = GraphThemePreferences(
                backgroundColour: Colors.blueGrey.shade50,
                edgeColour: Colors.blueGrey,
                edgeThickness: 0.2,
                nodeRadius: 15,
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
              return _selectedDemoIndex == 2
                  ? InteractiveGraph(
                      layoutAlgorithm: Eades(
                        graph: Graph.fromEdgeList(edges),
                      ),
                      themePreferences: theme,
                    )
                  : StaticGraph(
                      layoutAlgorithm: FruchtermanReingold(
                        graph: Graph.fromEdgeList(edges),
                      ),
                      themePreferences: theme,
                    );
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error fetching graph data'));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );

      default:
        throw ArgumentError.value(_selectedDemoIndex, '_selectedDemoIndex');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // A dropdown menu which selects the demo to display.
            DropdownButton(
              value: _selectedDemoIndex,
              onChanged: (value) {
                setState(() {
                  _selectedDemoIndex = value!;
                });
              },
              items: List.generate(
                _demoNames.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(_demoNames[i]),
                ),
              ),
            ),
            // The graph demo itself.
            _displayDemo(),
          ],
        ),
      ),
    );
  }
}
