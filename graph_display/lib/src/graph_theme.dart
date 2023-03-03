import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

import 'common.dart';

/// Theme preferences for drawing a graph.
///
/// This is a data class, it contains no methods.
class GraphThemePreferences {
  final void Function(Canvas, Size)? drawBackground;
  final void Function(Canvas, Edge, Vector2, Vector2)? drawEdge;
  final void Function(Canvas, Node, Vector2)? drawNode;

  final double edgeThickness;
  final double nodeRadius;

  final Color? backgroundColour;
  final Color? edgeColour;
  final Color? nodeColour;

  const GraphThemePreferences({
    this.drawBackground,
    this.drawEdge,
    this.drawNode,
    this.edgeThickness = 1,
    this.nodeRadius = 10,
    this.backgroundColour,
    this.edgeColour,
    this.nodeColour,
  });
}

/// This class takes a user's theme preferences [GraphThemePreferences] and a
/// colour scheme [ColorScheme] in the constructor (typically a [BuildContext]
/// is required to produce the latter), and makes available three callbacks
/// for drawing a graph using [CustomPainter]:
/// * [drawBackground]
/// * [drawEdge]
/// * [drawNode]
class GraphTheme {
  final void Function(Canvas, Size) drawBackground;
  final void Function(Canvas, Edge, Vector2, Vector2) drawEdge;
  final void Function(Canvas, Node, Vector2) drawNode;

  GraphTheme({
    required ColorScheme defaultColorScheme,
    required GraphThemePreferences partialGraphTheme,
  })  : drawBackground = partialGraphTheme.drawBackground ??
            ((Canvas canvas, Size size) {
              // A unit square serves as a background.
              canvas.drawRect(
                Rect.fromPoints(Offset.zero, Offset(size.width, size.height)),
                Paint()
                  ..color = partialGraphTheme.backgroundColour ??
                      defaultColorScheme.background,
              );
            }),
        drawEdge = partialGraphTheme.drawEdge ??
            ((Canvas canvas, Edge edge, Vector2 leftPosition,
                Vector2 rightPosition) {
              canvas.drawPath(
                  Path()
                    ..moveTo(leftPosition.x, leftPosition.y)
                    ..lineTo(rightPosition.x, rightPosition.y)
                    ..close(),
                  Paint()
                    ..strokeWidth = partialGraphTheme.edgeThickness
                    ..color = partialGraphTheme.edgeColour ??
                        defaultColorScheme.primary.withOpacity(0.25)
                    ..style = PaintingStyle.stroke);
            }),
        drawNode = partialGraphTheme.drawNode ??
            ((Canvas canvas, Node node, Vector2 position) {
              canvas.drawCircle(
                  position.toOffset(),
                  partialGraphTheme.nodeRadius,
                  Paint()
                    ..color = partialGraphTheme.nodeColour ??
                        defaultColorScheme.primary);
            });
}
