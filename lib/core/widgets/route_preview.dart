import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// Draws a recorded GPS route as a polyline scaled to fit the available
/// bounds. Entirely offline — no map tiles needed.
class RoutePreview extends StatelessWidget {
  final List<LatLng> points;
  final Color? routeColor;
  final double strokeWidth;
  final EdgeInsets padding;
  final Color background;

  const RoutePreview({
    super.key,
    required this.points,
    this.routeColor,
    this.strokeWidth = 4,
    this.padding = const EdgeInsets.all(16),
    this.background = const Color(0xFFEAF3EF),
  });

  @override
  Widget build(BuildContext context) {
    final color = routeColor ?? AppColors.primary;
    return Container(
      color: background,
      child: points.length < 2
          ? _EmptyState(color: color)
          : CustomPaint(
              painter: _RoutePainter(
                points: points,
                color: color,
                strokeWidth: strokeWidth,
                padding: padding,
              ),
              child: const SizedBox.expand(),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color color;
  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.route_rounded,
        size: 36,
        color: color.withOpacity(0.35),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;
  final EdgeInsets padding;

  _RoutePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latRange = (maxLat - minLat).abs();
    final lngRange = (maxLng - minLng).abs();
    // Prevent divide-by-zero on very short routes.
    final safeLatRange = latRange < 1e-6 ? 1e-6 : latRange;
    final safeLngRange = lngRange < 1e-6 ? 1e-6 : lngRange;

    final drawW = size.width - padding.horizontal;
    final drawH = size.height - padding.vertical;

    // Uniform scale so the route keeps its real shape.
    final scale = (drawW / safeLngRange).clamp(0.0, double.infinity);
    final scaleY = drawH / safeLatRange;
    final finalScale = scale < scaleY ? scale : scaleY;

    final routeW = safeLngRange * finalScale;
    final routeH = safeLatRange * finalScale;
    final offsetX = padding.left + (drawW - routeW) / 2;
    final offsetY = padding.top + (drawH - routeH) / 2;

    Offset project(LatLng p) {
      final x = offsetX + (p.longitude - minLng) * finalScale;
      // Flip Y — latitude grows north but canvas grows down.
      final y = offsetY + (maxLat - p.latitude) * finalScale;
      return Offset(x, y);
    }

    final first = project(points.first);
    final path = ui.Path()..moveTo(first.dx, first.dy);
    for (var i = 1; i < points.length; i++) {
      final pt = project(points[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Subtle white halo so the route reads on any background.
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = strokeWidth + 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final start = project(points.first);
    final end = project(points.last);

    canvas.drawCircle(start, strokeWidth + 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(start, strokeWidth - 0.5, Paint()..color = color);

    canvas.drawCircle(end, strokeWidth + 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      end,
      strokeWidth - 0.5,
      Paint()..color = AppColors.onSurface,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.points != points ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
