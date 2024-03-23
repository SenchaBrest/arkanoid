import 'dart:ui';
import 'package:flame/components.dart';

class LifeManager extends Component {
  List<Life> lives = [];
  final Vector2 position;
  final Size size;

  LifeManager({
    required this.position,
    required this.size,
  });

  late Vector2 lifeSize = Vector2(
    64 / 961 * size.width,
    size.height
  );

  void addLife() {
    late Vector2 lifePosition;

    if (lives.isEmpty) {
      lifePosition = position +
          Vector2(48 / 961 * size.width, 0);
    }
    else {
      lifePosition = position +
          Vector2(48 / 961 * size.width, 0) +
          Vector2(lives.length * (64 / 961 + 22 / 961) * size.width, 0);
    }

    final life = Life(position: lifePosition, size: lifeSize);
    add(life);
    lives.add(life);
  }

  void removeLife() {
    remove(lives.last);
    lives.removeLast();
  }
}

class Life extends SpriteComponent with HasGameRef {
  Life({required Vector2 position, required Vector2 size})
      : super(
    size: size,
    position: position,
  );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('life.png');
  }
}
