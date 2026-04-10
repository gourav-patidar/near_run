import 'package:flutter/material.dart';
import 'package:near_run/core/theme/app_colors.dart';
import 'package:near_run/core/theme/app_text_styles.dart';
import 'package:near_run/features/run_summary/viewmodel/run_summary_viewmodel.dart';
import 'package:provider/provider.dart';

class RunSummaryScreen extends StatelessWidget {
  final RunSummaryData? data;

  const RunSummaryScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RunSummaryViewModel(data: data),
      child: const _RunSummaryView(),
    );
  }
}

// ─── Root View ────────────────────────────────────────────────────────────────

class _RunSummaryView extends StatelessWidget {
  const _RunSummaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<RunSummaryViewModel>(
          builder: (ctx, vm, __) => ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _TopBar(),
              const SizedBox(height: 16),

              // ── Map recap card ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MapRecapCard(location: vm.summary.location),
              ),
              const SizedBox(height: 24),

              // ── Session Complete label + Run Recap header ───────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RecapHeader(vm: vm),
              ),
              const SizedBox(height: 20),

              // ── Big stat cards ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _BigStatCard(
                      label: 'DISTANCE',
                      value: vm.summary.distanceFormatted,
                      unit: 'km',
                    ),
                    const SizedBox(height: 12),
                    _BigStatCard(
                      label: 'TOTAL TIME',
                      value: vm.summary.timeFormatted,
                      unit: '',
                    ),
                    const SizedBox(height: 12),
                    _BigStatCard(
                      label: 'AVG PACE',
                      value: vm.summary.paceFormatted,
                      unit: '/km',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Calories + Heart Rate row ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'CALORIES',
                        value: vm.summary.calories.toString(),
                        unit: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'HEART RATE',
                        value: vm.summary.avgHeartRate.toString(),
                        unit: 'bpm',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Save / Discard actions ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _PrimaryActionButton(
                      label: vm.isSaving ? 'Saving...' : 'Save Run',
                      onTap: vm.isSaving ? null : () => vm.saveRun(context),
                    ),
                    const SizedBox(height: 12),
                    _SecondaryActionButton(
                      label: 'Discard',
                      onTap: () => vm.discardRun(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Run Summary', style: AppTextStyles.titleLarge),
        ],
      ),
    );
  }
}

class _MapRecapCard extends StatelessWidget {
  final String location;

  const _MapRecapCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F3EC), Color(0xFFDDECE3)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                location,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapHeader extends StatelessWidget {
  final RunSummaryViewModel vm;

  const _RecapHeader({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SESSION COMPLETE', style: AppTextStyles.chipLabel),
        const SizedBox(height: 8),
        Text(vm.summary.runName, style: AppTextStyles.headlineMedium),
        const SizedBox(height: 6),
        Text(vm.summary.dateFormatted, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _BigStatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.chipLabel),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.primary,
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(text: ' $unit', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.chipLabel),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
              ),
              children: [
                TextSpan(text: ' $unit', style: AppTextStyles.titleSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _PrimaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(label, style: AppTextStyles.labelLarge),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: BorderSide(color: AppColors.outlineVariant.withOpacity(0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(label, style: AppTextStyles.labelLarge),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.70)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.38,
        size.width * 0.50,
        size.height * 0.92,
        size.width * 0.68,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.26,
        size.width * 0.86,
        size.height * 0.34,
        size.width * 0.88,
        size.height * 0.18,
      );

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.70),
      7,
      Paint()..color = AppColors.surface,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.18),
      8,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
