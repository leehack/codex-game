import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/protocol.dart';

const ink = Color(0xFF0B0B0D);
const panel = Color(0xFF191713);
const panelLight = Color(0xFF242018);
const brass = Color(0xFFFFC857);
const ember = Color(0xFFFF4D6D);
const mint = Color(0xFF62FF9B);
const cyan = Color(0xFF55D6FF);
const cream = Color(0xFFFFF4D6);

class RetroPanel extends StatelessWidget {
  const RetroPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = panel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: brass, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 0,
            offset: Offset(5, 5),
          ),
          BoxShadow(color: Color(0x6655D6FF), blurRadius: 18),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PixelButton extends StatelessWidget {
  const PixelButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = brass,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    return FilledButton.icon(
      onPressed: active ? onPressed : null,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: const Color(0xFF38322A),
        foregroundColor: ink,
        disabledForegroundColor: cream.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class HpBar extends StatelessWidget {
  const HpBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.height = 18,
    super.key,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            Text(
              '$value / $maxValue',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ink,
            border: Border.all(color: cream.withValues(alpha: 0.28)),
          ),
          child: SizedBox(
            height: height,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CountdownDial extends StatelessWidget {
  const CountdownDial({
    required this.remainingMs,
    required this.totalMs,
    this.size = 92,
    super.key,
  });

  final int remainingMs;
  final int totalMs;
  final double size;

  @override
  Widget build(BuildContext context) {
    final seconds = (remainingMs / 1000).ceil().clamp(0, 99);
    final ratio = totalMs <= 0 ? 0.0 : (remainingMs / totalMs).clamp(0.0, 1.0);
    final urgent = seconds <= 5;
    final color = urgent
        ? ember
        : ratio < 0.45
        ? brass
        : mint;
    return TweenAnimationBuilder<double>(
      key: ValueKey('countdown-$seconds-$urgent'),
      tween: Tween(begin: urgent ? 0.92 : 1, end: urgent ? 1.08 : 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: CustomPaint(
        painter: _CountdownPainter(ratio: ratio, color: color, urgent: urgent),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$seconds',
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                Text(
                  'SEC',
                  style: TextStyle(
                    color: cream.withValues(alpha: 0.78),
                    fontSize: size * 0.11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownPainter extends CustomPainter {
  const _CountdownPainter({
    required this.ratio,
    required this.color,
    required this.urgent,
  });

  final double ratio;
  final Color color;
  final bool urgent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = size.shortestSide * 0.08;
    final arcRect = rect.deflate(inset);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..color = ink.withValues(alpha: 0.9);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.square
      ..color = cream.withValues(alpha: 0.18);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.square
      ..color = color;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * (urgent ? 0.12 : 0.095)
      ..strokeCap = StrokeCap.square
      ..color = color.withValues(alpha: urgent ? 0.26 : 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(arcRect, bg);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * ratio, false, glow);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * ratio, false, fg);
  }

  @override
  bool shouldRepaint(covariant _CountdownPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.color != color ||
        oldDelegate.urgent != urgent;
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    required this.category,
    this.selected = true,
    this.onTap,
    super.key,
  });

  final QuizCategorySpec category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? category.accent : cream.withValues(alpha: 0.22),
          width: selected ? 2 : 1,
        ),
        color: selected
            ? category.accent.withValues(alpha: 0.18)
            : ink.withValues(alpha: 0.72),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              color: selected ? category.accent : cream.withValues(alpha: 0.32),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                category.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? cream : cream.withValues(alpha: 0.58),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return badge;
    }
    return InkWell(onTap: onTap, child: badge);
  }
}

class ScanlineBackground extends StatelessWidget {
  const ScanlineBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ink,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [Color(0xFF1A2420), ink],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          child,
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()..color = Colors.white.withValues(alpha: 0.035);
    for (var y = 0.0; y < size.height; y += 5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), line);
    }
    final grid = Paint()..color = brass.withValues(alpha: 0.045);
    for (var x = 0.0; x < size.width; x += 42) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String compactTime(int milliseconds) {
  final seconds = (milliseconds / 1000).ceil();
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (minutes <= 0) {
    return '${rest}s';
  }
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
