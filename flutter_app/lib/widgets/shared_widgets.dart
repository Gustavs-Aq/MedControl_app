import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
//  STATUS BAR
// ═══════════════════════════════════════════════════════════════

class StatusBarWidget extends StatelessWidget {
  final bool dark;
  const StatusBarWidget({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final c = dark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: c)),
          Row(children: [
            _SignalBars(color: c),
            const SizedBox(width: 6),
            Icon(Icons.wifi, size: 16, color: c),
            const SizedBox(width: 4),
            _BatteryIcon(color: c),
          ]),
        ],
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final Color color;
  const _SignalBars({required this.color});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [5.0, 8.0, 11.0, 14.0]
            .map((h) => Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: Container(width: 3, height: h, color: color),
                ))
            .toList(),
      );
}

class _BatteryIcon extends StatelessWidget {
  final Color color;
  const _BatteryIcon({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 11,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        padding: const EdgeInsets.all(1.5),
        child: Container(
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(1)),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
//  BOTTOM NAVIGATION
// ═══════════════════════════════════════════════════════════════

class BottomNavigation extends StatelessWidget {
  final String active;
  final Function(String) onNavigate;

  const BottomNavigation(
      {super.key, required this.active, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('home', Icons.home_outlined, Icons.home, 'Início'),
          _item('medications', Icons.medication_outlined, Icons.medication,
              'Medicamentos'),
          _item('history', Icons.access_time_outlined, Icons.access_time,
              'Histórico'),
          _item('reports', Icons.bar_chart_outlined, Icons.bar_chart,
              'Relatórios'),
          _item('profile', Icons.person_outline, Icons.person, 'Perfil'),
        ],
      ),
    );
  }

  Widget _item(String id, IconData icon, IconData iconActive, String label) {
    final isActive = active == id;
    final color = isActive ? AppTheme.green : AppTheme.textLight;
    return GestureDetector(
      onTap: () => onNavigate(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? iconActive : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PILL ICON
// ═══════════════════════════════════════════════════════════════

class PillIcon extends StatelessWidget {
  final double size;
  const PillIcon({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _PillPainter());
}

class _PillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final blue = Paint()..color = AppTheme.blue;
    final green = Paint()..color = AppTheme.green;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.04
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(s.width * 0.6, s.height * 0.35);
    canvas.rotate(-0.785);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero,
            width: s.width * 0.35,
            height: s.height * 0.45),
        blue);
    canvas.restore();

    canvas.drawLine(Offset(s.width * 0.5, s.height * 0.275),
        Offset(s.width * 0.625, s.height * 0.4), white);

    canvas.save();
    canvas.translate(s.width * 0.425, s.height * 0.65);
    canvas.rotate(-0.785);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero,
            width: s.width * 0.35,
            height: s.height * 0.45),
        green);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  CIRCULAR PROGRESS PAINTER
// ═══════════════════════════════════════════════════════════════

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const CircularProgressPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppTheme.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(CircularProgressPainter o) =>
      o.progress != progress || o.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  BAR CHART PAINTER
// ═══════════════════════════════════════════════════════════════

class BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  const BarChartPainter(
      {required this.values, required this.labels, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final bw = size.width / (values.length * 1.5);
    final maxH = size.height * 0.75;
    final bottomY = size.height * 0.85;
    final spacing = (size.width - bw * values.length) / (values.length + 1);

    for (int i = 0; i < values.length; i++) {
      final barH = (values[i] / 100) * maxH;
      final x = spacing + i * (bw + spacing);

      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, bottomY - barH, bw, barH),
              const Radius.circular(6)),
          Paint()..color = colors[i]);

      _drawText(canvas, '${values[i].toInt()}%', 9,
          Offset(x + bw / 2, bottomY - barH - 14), const Color(0xFF374151),
          bold: true);
      _drawText(canvas, labels[i], 10, Offset(x + bw / 2, bottomY + 4),
          AppTheme.textGray);
    }
  }

  void _drawText(Canvas c, String text, double size, Offset center, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: size,
              color: color,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => true;
}

// ═══════════════════════════════════════════════════════════════
//  SNACK HELPER
// ═══════════════════════════════════════════════════════════════

void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? AppTheme.red : AppTheme.green,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
