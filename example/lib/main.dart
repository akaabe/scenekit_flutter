import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:scenekit_flutter/scenekit_flutter.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = new ScenekitFlutter();
  final _width = 600.0;
  final _height = 400.0;
  int cur = 0;
  @override
  initState() {
    super.initState();

    initializeController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void zoomToPos() {
    List<Pos> pos = [
      new Pos(x: 125.0, y: 57.0, z: 248.0),
      new Pos(x: 165.0, y: 57.0, z: 248.0),
      new Pos(x: 205.0, y: 57.0, z: 248.0),
      new Pos(x: 245.0, y: 57.0, z: 248.0),
      new Pos(x: 285.0, y: 57.0, z: 248.0),
    ];
    _controller.zoomToPos(pos[cur]);
    if (cur >= pos.length - 1) {
      cur = 0;
    } else {
      cur += 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('SceneKit Example'),
        ),
        body: new Center(
          child: new GestureDetector(
            child: new Container(
              width: _width,
              height: _height,
              child: _controller.isInitialized
                  ? new Texture(textureId: _controller.textureId)
                  : null,
            ),
            onTap: zoomToPos,
          ),
        ),
      ),
    );
  }

  Future<Null> initializeController() async {
    await _controller.initialize(_width, _height);
    setState(() {});
  }
}
