/// RFW-only widgets — widgets supported by RFW's `createCoreWidgets()`
/// that have no matching class name in Flutter.
///
/// These classes exist solely for build-time AST parsing by rfw_gen.
/// They are never instantiated at runtime.
library;

/// RFW equivalent of `SizedBox.shrink()`. Constrains child to 0x0.
class SizedBoxShrink {
  final Object? child;
  const SizedBoxShrink({this.child});
}

/// RFW equivalent of `SizedBox.expand()`. Expands child to fill available space.
class SizedBoxExpand {
  final Object? child;
  const SizedBoxExpand({this.child});
}

/// Rotation transform with implicit animation support.
/// RFW equivalent of Flutter's `RotatedBox` / `RotationTransition`.
class Rotation {
  final Object? turns;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Rotation({this.turns, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// Scale transform with implicit animation support.
/// RFW equivalent of Flutter's `Transform.scale`.
class Scale {
  final Object? scale;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Scale({this.scale, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// Sets default animation duration and curve for descendant widgets.
/// RFW-only concept with no direct Flutter equivalent.
class AnimationDefaults {
  final Object? duration;
  final Object? curve;
  final Object? child;
  const AnimationDefaults({this.duration, this.curve, this.child});
}
