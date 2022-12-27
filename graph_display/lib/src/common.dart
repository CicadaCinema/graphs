import 'dart:ui';

import 'package:vector_math/vector_math.dart';

extension OffsetToVector2 on Offset {
  Vector2 toVector2() => Vector2(dx, dy);
}

extension Vector2ToOffset on Vector2 {
  Offset toOffset() => Offset(x, y);
}

// TODO: See https://github.com/google/vector_math.dart/issues/189 .
extension SetToggle<T> on Set<T> {
  /// Toggles whether [element] is an element of this set.
  ///
  /// If [element] is not currently a member, it is added, and this method returns `true`.
  /// If [element] is currently a member, it is removed, and this method returns `false`.
  bool toggle(T element) => !remove(element) && add(element);
}
