import 'package:flutter/material.dart';

/// Decorative route illustration. Live directions open in the map application.
class RoutePreview extends StatelessWidget {
  const RoutePreview({
    super.key,
    required this.label,
    required this.onOpen,
    this.height = 180,
  });
  final String label;
  final VoidCallback onOpen;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StreetPainter())),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'en'
                    ? 'Route illustration'
                    : 'Ilustración de ruta',
                style: const TextStyle(fontSize: 9, color: Color(0xFF697480)),
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFED0824),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onOpen,
              icon: const Icon(Icons.location_on, size: 16),
              label: Text(label),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StreetPainter extends CustomPainter {
  const _StreetPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2F0EA),
    );
    final park = Paint()..color = const Color(0xFFD6EACD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .06,
          size.height * .48,
          size.width * .23,
          size.height * .35,
        ),
        const Radius.circular(12),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .72,
          size.height * .03,
          size.width * .24,
          size.height * .37,
        ),
        const Radius.circular(18),
      ),
      park,
    );
    final blocks = Paint()..color = const Color(0xFFE4E1D9);
    for (var x = -40.0; x < size.width; x += 58) {
      for (var y = 15.0; y < size.height; y += 45) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 40, 28),
            const Radius.circular(3),
          ),
          blocks,
        );
      }
    }
    final streets = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    for (var x = -size.height; x < size.width; x += 68) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        streets,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        streets,
      );
    }
    final route = Path()
      ..moveTo(size.width * .18, size.height * .75)
      ..lineTo(size.width * .34, size.height * .53)
      ..lineTo(size.width * .47, size.height * .64)
      ..lineTo(size.width * .67, size.height * .29)
      ..lineTo(size.width * .78, size.height * .36);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFFED0824)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final start = Offset(size.width * .18, size.height * .75);
    canvas.drawCircle(
      start,
      14,
      Paint()..color = const Color(0xFF2196F3).withValues(alpha: .2),
    );
    canvas.drawCircle(start, 9, Paint()..color = Colors.white);
    canvas.drawCircle(start, 7, Paint()..color = const Color(0xFF2196F3));
    final end = Offset(size.width * .78, size.height * .29);
    final pin = Path()
      ..moveTo(end.dx, end.dy + 22)
      ..quadraticBezierTo(end.dx - 25, end.dy - 2, end.dx - 13, end.dy - 14)
      ..quadraticBezierTo(end.dx, end.dy - 27, end.dx + 13, end.dy - 14)
      ..quadraticBezierTo(end.dx + 25, end.dy - 2, end.dx, end.dy + 22);
    canvas.drawPath(pin, Paint()..color = const Color(0xFFED0824));
    canvas.drawCircle(
      Offset(end.dx, end.dy - 6),
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _StreetPainter oldDelegate) => false;
}
