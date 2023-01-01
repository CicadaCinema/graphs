import 'dart:ui';

import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

extension OffsetToVector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

extension Vector2ToOffset on Vector2 {
  Offset toOffset() => Offset(x, y);
}

extension ClosestNode on NodeLayout {
  /// Returns the closest [Node] to the given [Vector2].
  Node closest(Vector2 position) => keys.reduce((a, b) {
    if (position.distanceTo(this[a]!) < position.distanceTo(this[b]!)) {
      return a;
    } else {
      return b;
    }
  });
}

// TODO: See https://github.com/google/vector_math.dart/issues/189 .
extension SetToggle<T> on Set<T> {
  /// Toggles whether [element] is an element of this set.
  ///
  /// If [element] is not currently a member, it is added, and this method
  /// returns `true`. If [element] is currently a member, it is removed, and
  /// this method returns `false`.
  bool toggle(T element) => !remove(element) && add(element);
}
