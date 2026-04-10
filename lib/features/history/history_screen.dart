import 'package:flutter/material.dart';
import 'package:near_run/core/theme/app_colors.dart';
import 'package:near_run/core/theme/app_text_styles.dart';
import 'package:near_run/features/history/viewmodel/history_viewmodel.dart';
import 'package:provider/provider.dart';


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HistoryViewModel(),
      child: const _HistoryView(),
    );
  }
}

// ─── Root View ────────────────────────────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Consumer<HistoryViewModel>(
                builder: (_, vm, __) {
                  if (vm.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (vm.isEmpty) {
                    return _EmptyState();
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.refresh,
                    child: CustomScrollView(
                      slivers: [
                        // ── Big heading ──────────────────────────────────
                        SliverToBoxAdapter(
                          child: _HistoryHeading(),
                        ),

                        // ── Run cards list ────────────────────────────────
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverList.separated(
                            itemCount: vm.runs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (ctx, i) => _RunCard(
                              run: vm.runs[i],
                              onTap: () => vm.onRunTapped(vm.runs[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, size: 26, color: AppColors.onSurface),
          const SizedBox(width: 12),
          Text(
            'near_run',
            style: AppTextStyles.brandTitle.copyWith(
              fontStyle: FontStyle.italic,
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              color: AppColors.primaryContainer,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Heading ──────────────────────────────────────────────────────────

class _HistoryHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'History',
            style: AppTextStyles.displaySmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 52,
              letterSpacing: -2,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
          Text(
            'YOUR KINETIC JOURNEY',
            style: AppTextStyles.chipLabel.copyWith(
              letterSpacing: 2.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Run Card ─────────────────────────────────────────────────────────────────

class _RunCard extends StatelessWidget {
  final RunRecord run;
  final VoidCallback onTap;
  const _RunCard({required this.run, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date + achievement badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        run.dateLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      if (run.hasAchievement) const _AchievementBadge(),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Run title
                  Text(
                    run.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stats row
                  run.duration != null
                      ? _ThreeStatRow(run: run)
                      : _TwoStatRow(run: run),
                ],
              ),
            ),

            // Map thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _MapThumbnail(style: run.mapStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Rows ────────────────────────────────────────────────────────────────

class _TwoStatRow extends StatelessWidget {
  final RunRecord run;
  const _TwoStatRow({required this.run});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          label: 'DISTANCE',
          value: run.distanceFormatted,
          unit: 'km',
          valueColor: AppColors.primary,
          valueFontSize: 24,
        ),
        const SizedBox(width: 32),
        _StatItem(
          label: 'PACE',
          value: run.pace,
          unit: '/km',
          valueColor: AppColors.onSurface,
          valueFontSize: 22,
        ),
      ],
    );
  }
}

class _ThreeStatRow extends StatelessWidget {
  final RunRecord run;
  const _ThreeStatRow({required this.run});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          label: 'DIST',
          value: run.distanceKm.toStringAsFixed(1),
          unit: '',
          valueColor: AppColors.onSurface,
          valueFontSize: 22,
        ),
        const SizedBox(width: 24),
        _StatItem(
          label: 'TIME',
          value: run.duration!,
          unit: '',
          valueColor: AppColors.onSurface,
          valueFontSize: 22,
        ),
        const SizedBox(width: 24),
        if (run.heartRateBpm != null)
          _StatItem(
            label: 'BPM',
            value: '${run.heartRateBpm}',
            unit: '',
            valueColor: AppColors.onSurface,
            valueFontSize: 22,
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final double valueFontSize;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.chipLabel),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: AppTextStyles.bodySmall),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Achievement Badge ────────────────────────────────────────────────────────

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        'ACHIEVEMENT',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Map Thumbnail ────────────────────────────────────────────────────────────

class _MapThumbnail extends StatelessWidget {
  final RunMapStyle style;
  const _MapThumbnail({required this.style});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapThumbnailPainter(style: style),
      child: const SizedBox.expand(),
    );
  }
}

class _MapThumbnailPainter extends CustomPainter {
  final RunMapStyle style;
  const _MapThumbnailPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case RunMapStyle.dark:
        _paintDark(canvas, size);
      case RunMapStyle.light:
        _paintLight(canvas, size);
      case RunMapStyle.terrain:
        _paintTerrain(canvas, size);
    }
  }

  void _paintDark(Canvas canvas, Size size) {
    // Dark city map
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1B2A),
    );

    // City grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2E42)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Route
    _drawRoute(canvas, size, AppColors.primaryContainer, width: 5);
  }

  void _paintLight(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.primaryContainer.withOpacity(0.25),
    );

    // Wavy river / path
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(
        size.width * 0.25, size.height * 0.3,
        size.width * 0.5, size.height * 0.7,
        size.width * 0.75, size.height * 0.4,
      )
      ..cubicTo(
        size.width * 0.88, size.height * 0.3,
        size.width, size.height * 0.45,
        size.width, size.height * 0.45,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 24
        ..style = PaintingStyle.stroke,
    );

    _drawRoute(canvas, size, AppColors.primary, width: 4);
  }

  void _paintTerrain(Canvas canvas, Size size) {
    // Dark terrain with contour lines
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0A2A1F),
    );

    final contourPaint = Paint()
      ..color = const Color(0xFF1A4D38)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Contour rings
    for (int i = 1; i <= 5; i++) {
      final ovalRect = Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.55),
        width: size.width * 0.25 * i,
        height: size.height * 0.18 * i,
      );
      canvas.drawOval(ovalRect, contourPaint);
    }

    // Neon green route accent
    _drawRoute(canvas, size, const Color(0xFF00FF88), width: 4);
  }

  void _drawRoute(Canvas canvas, Size size, Color color, {double width = 4}) {
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3, size.height * 0.2,
        size.width * 0.6, size.height * 0.3,
        size.width * 0.85, size.height * 0.55,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.85)
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Start dot
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.7),
      5,
      Paint()..color = color,
    );

    // End dot
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.55),
      5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_run_rounded,
            size: 64,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No runs yet',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your first run from the home screen',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
