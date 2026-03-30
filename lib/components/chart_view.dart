import 'package:flutter/material.dart';

/// Simple bar chart widget – no external packages needed.
/// [data] is a list of (label, value) pairs, sorted descending.
class SimpleBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final Color barColor;
  final String unit;
  final double height;
  final Color? textColor;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.barColor = const Color(0xFFD32F2F),
    this.unit = '',
    this.height = 180,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (data.isEmpty) return _empty(cs);

    final maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((entry) {
          final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.value.toInt()}$unit',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    height: ((height - 40) * ratio).clamp(4.0, height - 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          barColor,
                          barColor.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key.length > 8
                        ? '${entry.key.substring(0, 8)}…'
                        : entry.key,
                    style: TextStyle(
                      fontSize: 9,
                      color: textColor ?? cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _empty(ColorScheme cs) => Center(
        child: Text('Chưa có dữ liệu',
            style: TextStyle(color: textColor ?? cs.onSurfaceVariant)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

/// Simple 7-day line chart for revenue trend.
/// [points] is a list of (dayLabel, revenue) in chronological order.
class SimpleLineChart extends StatelessWidget {
  final List<MapEntry<String, double>> points;
  final Color lineColor;
  final double height;
  final Color? textColor;
  final Color? gridColor;

  const SimpleLineChart({
    super.key,
    required this.points,
    this.lineColor = const Color(0xFFD32F2F),
    this.height = 150,
    this.textColor,
    this.gridColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return Center(
        child: Text('Chưa có dữ liệu',
            style: TextStyle(color: textColor ?? cs.onSurfaceVariant)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              points: points.map((e) => e.value).toList(),
              lineColor: lineColor,
              fillColor: lineColor.withValues(alpha: 0.08),
              gridColor: gridColor ?? cs.outlineVariant.withValues(alpha: 0.4),
              showDots: points.length < 15, // Ẩn chấm nếu quá nhiều ngày (như tháng)
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        // Day labels
        Row(
          children: points.map((e) {
            return Expanded(
              child: Text(
                e.key,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, color: textColor ?? cs.onSurfaceVariant),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final bool showDots;

  _LinePainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    this.showDots = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final maxV = points.reduce((a, b) => a > b ? a : b);
    final minV = 0.0;
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double xStep = points.length > 1 ? size.width / (points.length - 1) : size.width;

    Offset toOffset(int i) {
      final x = i * xStep;
      final y = size.height - ((points[i] - minV) / range * size.height);
      return Offset(x, y.clamp(0, size.height));
    }

    // Fill path
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(toOffset(i).dx, toOffset(i).dy);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 1; i < points.length; i++) {
      final prev = toOffset(i - 1);
      final curr = toOffset(i);
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path, linePaint);

    // Dots (Optional)
    if (showDots) {
      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      final dotBorder = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      for (int i = 0; i < points.length; i++) {
        final o = toOffset(i);
        canvas.drawCircle(o, 5, dotBorder);
        canvas.drawCircle(o, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
