import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/hu_alphabet.dart';
import '../core/l10n.dart';

/// IPA 모음 사다리꼴 1장 위에 헝가리어 모음(자두 ●)과 가까운 한국어 모음(남색 ●)을 함께 찍는다(일본어앱 vowel_compare_chart.dart 를 옮김, 2026-11-08).
class VowelCompareChart extends StatelessWidget {
  final VowelChartData data;
  const VowelCompareChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.45,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.washiDeep,
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.fromLTRB(30, 22, 12, 12),
            child: CustomPaint(
              painter: _TrapezoidPainter(data),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _legendDot(AppColors.beni, tr('헝가리어')),
            const SizedBox(width: 12),
            _legendDot(AppColors.magyar, tr('한국어')),
          ],
        ),
        const SizedBox(height: 4),
        Text(data.note,
            style: const TextStyle(fontSize: 11.5, color: AppColors.sumi, height: 1.45)),
      ],
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
      ],
    );
  }
}

class _TrapezoidPainter extends CustomPainter {
  final VowelChartData data;
  _TrapezoidPainter(this.data);

  // IPA 사다리꼴: 위 변은 전체 폭, 아래 변은 오른쪽으로 치우침(전설 쪽이 안으로 기움)
  Offset _map(double x, double y, Size s) {
    final leftTop = 0.0;
    final leftBottom = 0.38 * s.width; // 저모음일수록 전설 경계가 오른쪽으로
    final left = leftTop + (leftBottom - leftTop) * y;
    final px = left + (s.width - left) * x;
    return Offset(px, y * s.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.sumiLight.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 외곽 사다리꼴
    final path = Path()
      ..moveTo(_map(0, 0, size).dx, _map(0, 0, size).dy)
      ..lineTo(_map(1, 0, size).dx, _map(1, 0, size).dy)
      ..lineTo(_map(1, 1, size).dx, _map(1, 1, size).dy)
      ..lineTo(_map(0, 1, size).dx, _map(0, 1, size).dy)
      ..close();
    canvas.drawPath(path, grid);

    // 가로선 (Close-mid, Open-mid) + 세로선 (Central)
    for (final y in [1 / 3, 2 / 3]) {
      canvas.drawLine(_map(0, y, size), _map(1, y, size), grid);
    }
    canvas.drawLine(_map(0.5, 0, size), _map(0.5, 1, size), grid);

    // 축 라벨
    _text(canvas, tr('전설'), Offset(_map(0, 0, size).dx - 2, -18), AppColors.sumiLight, 9,
        align: TextAlign.left);
    _text(canvas, tr('중설'), Offset(_map(0.5, 0, size).dx - 10, -18), AppColors.sumiLight, 9);
    _text(canvas, tr('후설'), Offset(size.width - 22, -18), AppColors.sumiLight, 9);
    _text(canvas, tr('고'), Offset(-24, _map(0, 0, size).dy - 5), AppColors.sumiLight, 9);
    _text(canvas, tr('중'), Offset(-24, _map(0, 0.5, size).dy - 5), AppColors.sumiLight, 9);
    _text(canvas, tr('저'), Offset(-24, size.height - 10), AppColors.sumiLight, 9);

    // 헝가리어 ↔ 한국어 연결 점선
    final hu = _map(data.hu.x, data.hu.y, size);
    for (final e in data.ko) {
      final p = _map(e.x, e.y, size);
      _dashedLine(canvas, hu, p,
          Paint()
            ..color = AppColors.sumiLight.withValues(alpha: 0.6)
            ..strokeWidth = 1);
    }

    // 한국어 점
    for (final e in data.ko) {
      final p = _map(e.x, e.y, size);
      canvas.drawCircle(p, 5, Paint()..color = AppColors.magyar);
      _pointLabel(canvas, size, p, '${e.ipa} ${e.label}', AppColors.magyar);
    }

    // 헝가리어 점(더 크게 + 테두리)
    canvas.drawCircle(hu, 7, Paint()..color = AppColors.beni);
    canvas.drawCircle(
        hu,
        7,
        Paint()
          ..color = AppColors.washi
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    _pointLabel(canvas, size, hu, '${data.hu.ipa} ${data.hu.label}', AppColors.beni, bold: true);
  }

  void _pointLabel(Canvas canvas, Size size, Offset p, String s, Color c, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: bold ? 12 : 10.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: c)),
      textDirection: TextDirection.ltr,
    )..layout();
    // 점 오른쪽에, 화면 밖으로 나가면 왼쪽에
    var dx = p.dx + 9;
    if (dx + tp.width > size.width) dx = p.dx - tp.width - 9;
    var dy = p.dy - tp.height / 2;
    if (dy < 0) dy = 0;
    if (dy + tp.height > size.height) dy = size.height - tp.height;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _text(Canvas canvas, String s, Offset o, Color c, double fs,
      {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: fs, color: c, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    tp.paint(canvas, o);
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0, gap = 3.0;
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    var t = 0.0;
    while (t < d) {
      final end = (t + dash).clamp(0.0, d);
      canvas.drawLine(a + dir * t, a + dir * end, paint);
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrapezoidPainter old) => old.data != data;
}
