import 'dart:ui';
import 'dart:ui' as ui;

import 'bullet.dart';
import 'paddle.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../forge2d_game_world.dart';
import '../utils/image_loader.dart';
import 'bonus.dart';



class Arena extends BodyComponent<Forge2dGameWorld> with ContactCallbacks {
  final Size size;
  final Vector2 position;
  final String imageArenaPath;
  final String gifExitPath;
  final String imageExitPath;
  
  ui.Image? imageArena;

  List<ui.Image> frames = [];
  int currentFrameIndex = 0;
  double timeSinceLastFrame = 0.0;
  double frameDuration = 0.005;

  ui.Image? imageExit;


  Arena({
    required this.size,
    required this.position,
    required this.imageArenaPath,
    required this.gifExitPath,
    required this.imageExitPath
  }) {
    assert(size.width >= 1.0 && size.height >= 1.0);
  }

  @override
  Future<void> onLoad() async {
    imageArena = await ImageLoader.loadImage(imageArenaPath);
    frames = await ImageLoader.loadGif(gifExitPath);
    imageExit = await ImageLoader.loadImage(imageExitPath);

    return super.onLoad();
  }

  void renderExtraImage(Canvas canvas, image, positionX, positionY, sizeX, sizeY) {
    if (image != null) {
      final Rect srcRect = Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());
      final Rect destRect = Rect.fromLTWH(
        positionX,
        positionY,
        sizeX,
        sizeY,
      );
      canvas.drawImageRect(image!, srcRect, destRect, Paint());
    }
  }

  void drawGifForPinkBonus(Canvas canvas) {
    if (frames.isNotEmpty) {
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        frames[currentFrameIndex].width.toDouble(),
        frames[currentFrameIndex].height.toDouble(),
      );
      final Rect destRect = Rect.fromLTWH(
        size.width * ((1033 - 43) / 1033) + position.x,
        size.height * ((1060 - 128) / 1060) + position.y,
        size.width * 43 / 1033,
        size.height * 128 / 1060,
      );
      canvas.drawImageRect(
        frames[currentFrameIndex],
        srcRect,
        destRect,
        Paint(),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (frames.isNotEmpty) {
      timeSinceLastFrame += dt;
      if (timeSinceLastFrame >= frameDuration) {
        timeSinceLastFrame = 0.0;
        currentFrameIndex = (currentFrameIndex + 1) % frames.length;
      }
    }
  }

  bool showExit = false;

  @override
  void render(Canvas canvas) {
    if (imageArena != null) {
      final Rect destRect = Rect.fromLTWH(
          0 + position.x,
          0 + position.y,
          size.width,
          size.height
      );
      final Rect srcRect = Rect.fromLTWH(0, 0, imageArena!.width.toDouble(), imageArena!.height.toDouble());
      canvas.drawImageRect(imageArena!, srcRect, destRect, Paint());
    }
    if (gameRef.bonusState == BonusState.pink) {
      if (!showExit) {
        drawGifForPinkBonus(canvas);
      } else {
        renderExtraImage(
          canvas,
          imageExit,
          size.width * ((1033 - 43) / 1033) + position.x,
          size.height * ((1060 - 128) / 1060) + position.y,
          size.width * 43 / 1033,
          size.height * 128 / 1060,
        );
      }
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is Paddle) {
      if (gameRef.bonusState == BonusState.pink && other.body.position.x > size.width / 2) {
        showExit = true;
      }
    }
  }

  @override
  Body createBody() {
    final ratio = Vector2(0.0, 0.0);
    ratio.x = (1033 - 43) / 1033;
    ratio.y = (1060 - 43) / 1060;

    final bodyDef = BodyDef()
      ..userData = this
      ..position = Vector2(0, 0)
      ..type = BodyType.static;

    final arenaBody = world.createBody(bodyDef);

    final vertices = <Vector2>[
      Vector2(size.width * ratio.x + position.x, size.height * ratio.y + position.y),
      Vector2(size.width * (1 - ratio.x) + position.x, size.height * ratio.y + position.y),
      Vector2(size.width * (1 - ratio.x) + position.x, size.height * (1 - ratio.y) + position.y),
      Vector2(size.width * ratio.x + position.x, size.height * (1 - ratio.y) + position.y),
    ];

    final chain = ChainShape()..createLoop(vertices);

    for (var index = 0; index < chain.childCount; index++) {
      arenaBody.createFixture(
        FixtureDef(chain.childEdge(index))
          ..density = 2000.0
          ..friction = 0.0
          ..restitution = 0.4,
      );
    }

    return arenaBody;
  }
}