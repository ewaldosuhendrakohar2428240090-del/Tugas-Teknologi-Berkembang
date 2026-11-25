import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = AppTheme.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QrCodePainter(data: data, foregroundColor: color),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  final String data;
  final Color foregroundColor;

  _QrCodePainter({required this.data, required this.foregroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;

    const int gridCount = 21; // Standard QR Version 1 grid
    final double cellSize = size.width / gridCount;

    // Pseudo-deterministic random pattern derived from data string
    int seed = data.codeUnits.fold(0, (prev, elem) => prev + elem);
    final random = Random(seed);

    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        // Position Detection Patterns (Top-Left, Top-Right, Bottom-Left corners)
        final isTopLeft = r < 7 && c < 7;
        final isTopRight = r < 7 && c >= gridCount - 7;
        final isBottomLeft = r >= gridCount - 7 && c < 7;

        if (isTopLeft || isTopRight || isBottomLeft) {
          final localR = isTopLeft ? r : (isTopRight ? r : r - (gridCount - 7));
          final localC = isTopLeft ? c : (isTopRight ? c - (gridCount - 7) : c);

          // Outer border (7x7) or Inner box (3x3)
          final isBorder = localR == 0 || localR == 6 || localC == 0 || localC == 6;
          final isInnerBox = localR >= 2 && localR <= 4 && localC >= 2 && localC <= 4;

          if (isBorder || isInnerBox) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.95, cellSize * 0.95),
                const Radius.circular(2),
              ),
              paint,
            );
          }
        } else {
          // Internal data dots
          if (random.nextBool() && !(r > 8 && r < 12 && c > 8 && c < 12)) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.9, cellSize * 0.9),
                const Radius.circular(1.5),
              ),
              paint,
            );
          }
        }
      }
    }

    // Center Pet Paw icon badge
    final centerBadgeSize = cellSize * 5;
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: centerBadgeSize,
      height: centerBadgeSize,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      cellSize * 1.5,
      Paint()..color = foregroundColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
