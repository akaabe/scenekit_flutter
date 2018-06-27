import 'dart:async';

import 'package:flutter/services.dart';

class Pos {
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  Pos({this.x, this.y, this.z});
}

class ScenekitFlutter {
  static const MethodChannel _channel = const MethodChannel('scenekit_flutter');

  int textureId;

  Future<int> initialize(double width, double height) async {
    textureId = await _channel.invokeMethod('create', {
      'width': width,
      'height': height,
    });
    return textureId;
  }

  Future<Null> zoomToPos(Pos pos) async {
    await _channel.invokeMethod(
        'zoom_to_pos', {'pos_x': pos.x, 'pos_y': pos.y, 'pos_z': pos.z});
  }

  Future<Null> zoomToItem(int item) async {
    await _channel.invokeMethod('zoom_to_item', {'item': item});
  }

  Future<Null> dispose() =>
      _channel.invokeMethod('dispose', {'textureId': textureId});

  bool get isInitialized => textureId != null;
}
