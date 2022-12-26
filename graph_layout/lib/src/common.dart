import 'package:vector_math/vector_math.dart';

import 'data_structures.dart';

extension NodeLayoutExt on NodeLayout {
  /// Returns the closest [Node] to the given [Vector2].
  Node closest(Vector2 position) => keys.reduce((a, b) {
        if (position.distanceTo(this[a]!) < position.distanceTo(this[b]!)) {
          return a;
        } else {
          return b;
        }
      });
}
