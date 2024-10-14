import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_tilt.g.dart';

enum DeviceTiltState {
  right,
  center,
  left,
}

const methodChannel = MethodChannel('deviceMotionUpdates');

/// デバイスの角度の閾値
const rollThreshold = 40;

/// centerへ戻る時のrollの閾値
const rollThresholdToCenter = 15;

@riverpod
class DeviceTilt extends _$DeviceTilt {
  @override
  DeviceTiltState build() {
    methodChannel.setMethodCallHandler((call) async {
      final roll = double.tryParse(call.arguments['roll'].toString());
      if (roll == null) {
        return;
      }
      // centerからright or leftに汎化する時はrollThresholdを超えているかどうかで判断する。
      if (state == DeviceTiltState.center) {
        if (roll > rollThreshold) {
          state = DeviceTiltState.right;
        } else if (roll < -rollThreshold) {
          state = DeviceTiltState.left;
        }
      }
      // right or leftからcenterに変化する時はrollThresholdから-10した値を超えているかどうかで判断する。
      else {
        if (roll.abs() < rollThresholdToCenter) {
          state = DeviceTiltState.center;
        }
      }
    });
    return DeviceTiltState.center;
  }
}
