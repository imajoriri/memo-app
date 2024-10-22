import 'dart:ui';

import 'package:flutter/material.dart';

class TokeruSpacingExtension extends ThemeExtension<TokeruSpacingExtension> {
  TokeruSpacingExtension({
    required this.none,
    required this.smallX,
    required this.small,
    required this.medium,
    required this.large,
  });

  final double none;
  final double smallX;
  final double small;
  final double medium;
  final double large;

  @override
  ThemeExtension<TokeruSpacingExtension> copyWith({
    double? none,
    double? smallX,
    double? small,
    double? medium,
    double? large,
  }) {
    return TokeruSpacingExtension(
      none: none ?? this.none,
      smallX: smallX ?? this.smallX,
      small: small ?? this.small,
      medium: medium ?? this.medium,
      large: large ?? this.large,
    );
  }

  @override
  ThemeExtension<TokeruSpacingExtension> lerp(
    covariant ThemeExtension<TokeruSpacingExtension>? other,
    double t,
  ) {
    if (other is! TokeruSpacingExtension) {
      return this;
    }

    return TokeruSpacingExtension(
      none: lerpDouble(none, other.none, t)!,
      smallX: lerpDouble(smallX, other.smallX, t)!,
      small: lerpDouble(small, other.small, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      large: lerpDouble(large, other.large, t)!,
    );
  }
}
