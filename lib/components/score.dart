import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Score extends Component {
  final Size size;
  final Vector2 position;
  String scoreText;
  String highScoreText;

  final Paint _backgroundPaint = Paint()..color = Colors.black;
  late TextStyle _textStyle;

  Score({
    required this.size,
    required Vector2 position,
    required int score,
    required int highScore,
  })  : position = position.clone(),
        scoreText = score.toString(),
        highScoreText = highScore.toString(),
        super() {
    _textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.height / 2.1,
      fontWeight: FontWeight.bold,
      fontFamily: 'PressStart2P',
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(position.x, position.y, size.width, size.height), _backgroundPaint);

    final highScoreTextPainter = TextPainter(
      text: TextSpan(
        text: 'HIGH SCORE',
        style: _textStyle.copyWith(color: Colors.red),
      ),
      textDirection: TextDirection.ltr,
    );
    highScoreTextPainter.layout();
    highScoreTextPainter.paint(canvas, Offset(position.x + (size.width - highScoreTextPainter.width) / 2, position.y));

    final scoreValueTextPainter = TextPainter(
      text: TextSpan(
        text: scoreText,
        style: _textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    scoreValueTextPainter.layout();
    scoreValueTextPainter.paint(canvas, Offset(position.x + 3, position.y + size.height / 2));

    final highScoreValueTextPainter = TextPainter(
      text: TextSpan(
        text: highScoreText,
        style: _textStyle,
      ),
      textDirection: TextDirection.ltr,
    );
    highScoreValueTextPainter.layout();
    highScoreValueTextPainter.paint(canvas, Offset(position.x + (size.width - highScoreValueTextPainter.width) / 2, position.y + size.height / 2));
  }

  void updateScore({required int score, required int highScore}) {
    scoreText = score.toString();
    highScoreText = highScore.toString();
  }
}
