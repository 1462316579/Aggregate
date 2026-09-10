library screen_brightness_android;

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const MethodChannel _channel = MethodChannel('screen_brightness_android');

class ScreenBrightnessAndroidPlugin extends ScreenBrightnessPlatform {
  @override
  Future<double> get brightness async {
    try {
      final double result = await _channel.invokeMethod('get_brightness');
      return result;
    } on PlatformException catch (e) {
      return 0.5;
    }
  }

  @override
  Future<void> setBrightness(double brightness) async {
    await _channel.invokeMethod('set_brightness', {'brightness': brightness});
  }

  @override
  Stream<double> get brightnessStream {
    const EventChannel eventChannel =
        EventChannel('screen_brightness_android/brightness_stream');
    return eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => event as double);
  }
}
