import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../ui/retro_widgets.dart';
import 'protocol.dart';

class BattleSceneGame extends FlameGame {
  RoomSnapshot? snapshot;
  double _time = 0;

  @override
  Color backgroundColor() => ink;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) {
      return;
    }

    _drawBackdrop(canvas, width, height);
    _drawArena(canvas, width, height);
    _drawParty(canvas, width, height);
    _drawBoss(canvas, width, height);
    _drawActionStorm(canvas, width, height);
    _drawEndEffects(canvas, width, height);
    _drawHudText(canvas, width, height);

    super.render(canvas);
  }

  void _drawBackdrop(Canvas canvas, double width, double height) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF12100E), Color(0xFF07110F)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bg);

    final starPaint = Paint()..color = cyan.withValues(alpha: 0.22);
    for (var i = 0; i < 80; i++) {
      final x = (i * 73 + math.sin(i) * 19) % width;
      final y = (i * 41 + math.cos(i) * 29) % (height * 0.55);
      final pulse = 0.4 + 0.6 * math.sin(_time * 2 + i);
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        starPaint..color = cyan.withValues(alpha: 0.05 + pulse * 0.16),
      );
    }

    final mountain = Paint()..color = const Color(0xFF221B20);
    final path = Path()
      ..moveTo(0, height * 0.58)
      ..lineTo(width * 0.14, height * 0.42)
      ..lineTo(width * 0.32, height * 0.56)
      ..lineTo(width * 0.48, height * 0.38)
      ..lineTo(width * 0.66, height * 0.57)
      ..lineTo(width * 0.84, height * 0.45)
      ..lineTo(width, height * 0.6)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(path, mountain);
  }

  void _drawArena(Canvas canvas, double width, double height) {
    final floorTop = height * 0.63;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, width, height - floorTop),
      Paint()..color = const Color(0xFF231F16),
    );

    final grid = Paint()
      ..strokeWidth = 2
      ..color = brass.withValues(alpha: 0.14);
    for (var y = floorTop; y < height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(width, y), grid);
    }
    for (var x = -width; x < width * 2; x += 58) {
      canvas.drawLine(
        Offset(x + math.sin(_time) * 6, floorTop),
        Offset(x + width * 0.32, height),
        grid,
      );
    }

    final portalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = cyan.withValues(alpha: 0.45 + math.sin(_time * 3) * 0.12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.76, floorTop - 18),
        width: width * 0.22,
        height: height * 0.2,
      ),
      portalPaint,
    );
  }

  void _drawParty(Canvas canvas, double width, double height) {
    final playerCount = snapshot?.playerCount ?? 4;
    final answeredCount = snapshot?.answeredCount ?? 0;
    final floor = height * 0.73;
    final visible = math.max(4, math.min(10, playerCount));
    final startX = width * 0.1;
    for (var index = 0; index < visible; index++) {
      final active = index < playerCount;
      final answered = index < answeredCount;
      final x = startX + index * width * 0.052;
      final bob = math.sin(_time * 4 + index) * 4;
      _drawHero(
        canvas,
        Offset(x, floor + bob),
        (answered ? mint : cyan).withValues(alpha: active ? 1 : 0.22),
        answered ? 'A' : '?',
        index == visible - 1 && playerCount > visible ? playerCount : index + 1,
      );
    }
  }

  void _drawHero(
    Canvas canvas,
    Offset origin,
    Color color,
    String letter,
    int labelNumber,
  ) {
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: origin + const Offset(0, 43),
        width: 54,
        height: 13,
      ),
      shadow,
    );

    final scale = 4.0;
    _rect(canvas, origin, 4, 0, 6, 5, scale, color);
    _rect(canvas, origin, 2, 5, 10, 8, scale, color.withValues(alpha: 0.8));
    _rect(canvas, origin, 4, 13, 3, 5, scale, const Color(0xFF2B2723));
    _rect(canvas, origin, 9, 13, 3, 5, scale, const Color(0xFF2B2723));
    _rect(canvas, origin, 5, 2, 1, 1, scale, ink);
    _rect(canvas, origin, 9, 2, 1, 1, scale, ink);
    _rect(canvas, origin, 1, 7, 2, 2, scale, brass);
    _rect(canvas, origin, 12, 7, 2, 2, scale, brass);

    _drawText(
      canvas,
      labelNumber > 9 ? '$labelNumber' : letter,
      origin + const Offset(17, 86),
      14,
      cream,
      anchor: TextAnchor.center,
    );
  }

  void _drawBoss(Canvas canvas, double width, double height) {
    final snap = snapshot;
    final hpRatio = snap == null || snap.bossHpMax == 0
        ? 1.0
        : (snap.bossHp / snap.bossHpMax).clamp(0.0, 1.0);
    final phase = hpRatio <= 0.34
        ? 3
        : hpRatio <= 0.68
        ? 2
        : 1;
    final rage = 1 - hpRatio;
    final origin = Offset(width * 0.68, height * 0.42);
    final wobble = math.sin(_time * (3 + phase) + rage * 8) * (4 + phase * 1.5);
    final scale = math.max(4.5, width / 190);
    final base = switch (phase) {
      3 => ember,
      2 => const Color(0xFFFF8F3D),
      _ => const Color(0xFFA36CFF),
    };

    final glow = Paint()
      ..color = base.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(origin + Offset(wobble, 20), 105 + rage * 35, glow);

    final o = origin + Offset(wobble, math.sin(_time * 5) * 5);
    _rect(canvas, o, 7, 0, 14, 5, scale, base);
    _rect(canvas, o, 3, 5, 22, 14, scale, base.withValues(alpha: 0.88));
    _rect(canvas, o, 0, 10, 5, 8, scale, base.withValues(alpha: 0.72));
    _rect(canvas, o, 23, 10, 5, 8, scale, base.withValues(alpha: 0.72));
    _rect(canvas, o, 6, 19, 5, 6, scale, const Color(0xFF2E1424));
    _rect(canvas, o, 17, 19, 5, 6, scale, const Color(0xFF2E1424));
    _rect(canvas, o, 8, 8, 3, 3, scale, mint);
    _rect(canvas, o, 17, 8, 3, 3, scale, mint);
    _rect(canvas, o, 10, 14, 8, 2, scale, ink);
    _rect(canvas, o, 11, 2, 2, 2, scale, cream);
    _rect(canvas, o, 15, 2, 2, 2, scale, cream);

    final label = switch (phase) {
      3 => 'FINAL QUESTION CORE',
      2 => 'TRIVIA STORM',
      _ => 'QUIZ BOSS',
    };
    _drawText(canvas, label, Offset(width * 0.77, height * 0.22), 18, brass);
  }

  void _drawActionStorm(Canvas canvas, double width, double height) {
    final snap = snapshot;
    if (snap == null || snap.totalTallies == 0) {
      return;
    }

    final question = snap.currentQuestion;
    final category = question == null
        ? fallbackCategories.first
        : categoryById(question.categoryId, snap.categories);
    var index = 0;
    for (final entry in snap.tallies.entries) {
      final isCorrect = snap.lastResult?.correctIndex.toString() == entry.key;
      final color = isCorrect ? mint : category.accent;
      for (var i = 0; i < math.min(entry.value, 9); i++) {
        final phase = (_time * 0.7 + i * 0.08 + index * 0.13) % 1.0;
        final x = width * (0.24 + phase * 0.48);
        final arc = math.sin(phase * math.pi);
        final y = height * (0.56 - arc * 0.28) + i * 3;
        final size = 6.0 + arc * 8;
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: size, height: size),
          Paint()..color = color.withValues(alpha: 0.85),
        );
      }
      index += 1;
    }
  }

  void _drawEndEffects(Canvas canvas, double width, double height) {
    final snap = snapshot;
    if (snap == null || !snap.isFinished) {
      return;
    }

    final victory = snap.isVictory;
    final overlay = Paint()
      ..color = (victory ? mint : ember).withValues(alpha: 0.12);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), overlay);

    if (victory) {
      for (var i = 0; i < 90; i++) {
        final drift = (_time * (45 + i % 7 * 8) + i * 31) % (height + 90);
        final x = (i * 67 + math.sin(_time * 1.7 + i) * 40) % width;
        final y = drift - 70;
        final color = switch (i % 5) {
          0 => brass,
          1 => mint,
          2 => cyan,
          3 => cream,
          _ => const Color(0xFFFF8F3D),
        };
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(_time * 3 + i);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
          Paint()..color = color.withValues(alpha: 0.88),
        );
        canvas.restore();
      }

      final burst = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = mint.withValues(alpha: 0.35 + math.sin(_time * 8) * 0.12);
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
          Offset(width * 0.72, height * 0.47),
          ((_time * 95 + i * 34) % 190) + 20,
          burst,
        );
      }
    } else {
      final glitch = Paint()..color = ember.withValues(alpha: 0.16);
      for (var i = 0; i < 14; i++) {
        final y = (i * 47 + _time * 120) % height;
        final w = width * (0.18 + (i % 5) * 0.08);
        final x = (math.sin(_time * 8 + i) * width * 0.24) + width * 0.5;
        canvas.drawRect(Rect.fromLTWH(x, y, w, 5), glitch);
      }
      final warning = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = ember.withValues(alpha: 0.4 + math.sin(_time * 9) * 0.14);
      canvas.drawCircle(Offset(width * 0.7, height * 0.48), 160, warning);
    }
  }

  void _drawHudText(Canvas canvas, double width, double height) {
    final snap = snapshot;
    final title = snap == null
        ? 'WAITING FOR SERVER'
        : snap.phase == 'victory'
        ? 'QUIZ BOSS PATCHED'
        : snap.phase == 'defeat'
        ? 'BOSS SURVIVED'
        : snap.phase == 'battle'
        ? 'QUESTION ${snap.window + 1}/${snap.quizCount}'
        : 'SCAN TO JOIN';
    _drawText(canvas, title, Offset(width * 0.04, height * 0.08), 20, cream);
  }

  void _rect(
    Canvas canvas,
    Offset origin,
    int x,
    int y,
    int width,
    int height,
    double scale,
    Color color,
  ) {
    canvas.drawRect(
      Rect.fromLTWH(
        origin.dx + x * scale,
        origin.dy + y * scale,
        width * scale,
        height * scale,
      ),
      Paint()..color = color,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double size,
    Color color, {
    TextAnchor anchor = TextAnchor.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (anchor) {
      TextAnchor.center => offset.dx - painter.width / 2,
      TextAnchor.right => offset.dx - painter.width,
      TextAnchor.left => offset.dx,
    };
    painter.paint(canvas, Offset(dx, offset.dy));
  }
}

enum TextAnchor { left, center, right }
