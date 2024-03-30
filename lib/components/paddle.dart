import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/rendering.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../forge2d_game_world.dart';

class Paddle extends BodyComponent<Forge2dGameWorld> with Draggable {
  Size size;
  final BodyComponent ground;
  final Vector2 position;
  ui.Image? image;

  Paddle({
    required this.size,
    required this.ground,
    required this.position,
    required String imagePath,
  }) {
    _loadImage(imagePath);
  }

  Future<void> _loadImage(String imagePath) async {
    final data = await rootBundle.load(imagePath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    image = frame.image;
  }

  @override
  void render(Canvas canvas) {
    if (image != null) {
      final shape = body.fixtures.first.shape as PolygonShape;
      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromPoints(
          Offset(shape.vertices[0].x, shape.vertices[0].y),
          Offset(shape.vertices[2].x, shape.vertices[2].y),
        ),
        Paint(),
      );
    }
  }

  MouseJoint? _mouseJoint;
  Vector2 dragStartPosition = Vector2.zero();
  Vector2 dragAccumlativePosition = Vector2.zero();

  @override
  Body createBody() {
    final bodyDef = BodyDef()
      ..userData = this
      ..type = BodyType.dynamic
      ..position = position
      ..fixedRotation = true
      ..angularDamping = 1.0
      ..linearDamping = 10.0;

    final paddleBody = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );

    paddleBody.createFixture(FixtureDef(shape)
      ..density = 100.0
      ..friction = 0.0
      ..restitution = 1.0);

    return paddleBody;
  }

  void updateBody({required Size newSize, required String imagePath}) {
    size = newSize;

    final shape = PolygonShape()
      ..setAsBox(
        size.width / 2.0,
        size.height / 2.0,
        Vector2(0.0, 0.0),
        0.0,
      );
    body.destroyFixture(body.fixtures.first);
    body.createFixture(FixtureDef(shape)
      ..density = 100.0
      ..friction = 0.0
      ..restitution = 1.0);
    _loadImage(imagePath);
  }

  @override
  void onMount() {
    super.onMount();

    final worldAxis = Vector2(1.0, 0.0);

    final travelExtent = (gameRef.size.x * ((1033 - 2 * 43) / 1033)  / 2) - (size.width / 2.0);

    final jointDef = PrismaticJointDef()
      ..enableLimit = true
      ..lowerTranslation = -travelExtent
      ..upperTranslation = travelExtent
      ..collideConnected = true;

    jointDef.initialize(body, ground.body, body.worldCenter, worldAxis);
    final joint = PrismaticJoint(jointDef);
    world.createJoint(joint);
  }

  @override
  bool onDragStart(DragStartInfo info) {
    if (_mouseJoint != null) {
      return true;
    }
    dragStartPosition = info.eventPosition.game;
    _setupDragControls();

    // Don't continue passing the event.
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateInfo info) {
    dragAccumlativePosition += info.delta.game;
    if ((dragAccumlativePosition - dragStartPosition).length > 0.1) {
      _mouseJoint?.setTarget(dragAccumlativePosition);
      dragStartPosition = dragAccumlativePosition;
    }

    // Don't continue passing the event.
    return false;
  }

  @override
  bool onDragEnd(DragEndInfo info) {
    _resetDragControls();

    // Don't continue passing the event.
    return false;
  }

  @override
  bool onDragCancel() {
    _resetDragControls();

    // Don't continue passing the event.
    return false;
  }

  void _setupDragControls() {
    final mouseJointDef = MouseJointDef()
      ..bodyA = ground.body
      ..bodyB = body
      ..frequencyHz = 5.0
      ..dampingRatio = 0.9
      ..collideConnected = false
      ..maxForce = 2000.0 * body.mass;

    _mouseJoint = MouseJoint(mouseJointDef);
    world.createJoint(_mouseJoint!);
  }

  void _resetDragControls() {
    dragAccumlativePosition = Vector2.zero();
    if (_mouseJoint != null) {
      world.destroyJoint(_mouseJoint!);
      _mouseJoint = null;
    }
  }

  void reset() {
    body.setTransform(position, angle);
    body.angularVelocity = 0.0;
    body.linearVelocity = Vector2.zero();
    onDragCancel();
  }
}
