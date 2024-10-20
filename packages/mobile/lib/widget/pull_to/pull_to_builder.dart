import 'package:flutter/material.dart';
import 'package:mobile/widget/pull_to/pull_to_mode.dart';

typedef PullToIndicatorBuilder = Widget Function({
  required BuildContext context,
  required PullToMode mode,
  required double pulledExtent,
  required double refreshTriggerPullDistance,
  required double refreshIndicatorExtent,
});
