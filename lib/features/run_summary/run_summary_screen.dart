import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/route_preview.dart';
import 'viewmodel/run_summary_viewmodel.dart';

class RunSummaryScreen extends StatelessWidget {
  final RunModel run;

  /// When true, the run is already saved — show Delete / Close instead of
  /// Save / Discard. Used when opening a run from history.
  final bool isReadOnly;

  const RunSummaryScreen({
    super.key,
    required this.run,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RunSummaryViewModel(run: run, isReadOnly: isReadOnly),
      child: const _RunSummaryView(),
    );
  }
}

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
              _TopBar(run: vm.run, runName: vm.runName),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MapRecapCard(points: vm.run.routePoints),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RecapHeader(vm: vm),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _BigStatCard(
                      label: 'DISTANCE',
                      value: vm.run.distanceFormatted,
                      unit: 'km',
                    ),
                    const SizedBox(height: 12),
                    _BigStatCard(
                      label: 'TOTAL TIME',
                      value: vm.run.durationFormatted,
                      unit: '',
                    ),
                    const SizedBox(height: 12),
                    _BigStatCard(
                      label: 'AVG PACE',
                      value: vm.run.paceFormatted ?? '--',
                      unit: '/km',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'CALORIES',
                        value: vm.estimatedCalories.toString(),
                        unit: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'ELEVATION',
                        value:
                            (vm.run.elevationGainMeters ?? 0).round().toString(),
                        unit: 'm',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ActionButtons(vm: vm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final RunModel run;
  final String runName;
  const _TopBar({required this.run, required this.runName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context).maybePop(false),
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
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              final summaryText =
                  '🏃‍♂️ $runName\n📍 Distance: ${run.distanceFormatted} km\n⏱️ Duration: ${run.durationFormatted}\n⚡ Pace: ${run.paceFormatted ?? "--"}/km\nRecorded with NearRun';
              Clipboard.setData(ClipboardData(text: summaryText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Run summary copied to clipboard!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapRecapCard extends StatelessWidget {
  final List<dynamic> points;
  const _MapRecapCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: RoutePreview(
          points: points.cast(),
          background: const Color(0xFFE8F3EC),
          strokeWidth: 5,
        ),
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
        Text(
          vm.isReadOnly ? 'RUN DETAILS' : 'SESSION COMPLETE',
          style: AppTextStyles.chipLabel,
        ),
        const SizedBox(height: 6),
        Text(vm.runName, style: AppTextStyles.headlineMedium.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEE, MMM d • h:mm a').format(vm.run.startTime),
          style: AppTextStyles.bodyMedium,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.chipLabel),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTextStyles.displaySmall.copyWith(
                fontSize: 32,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.chipLabel),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: value,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 22,
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

class _ActionButtons extends StatelessWidget {
  final RunSummaryViewModel vm;
  const _ActionButtons({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isReadOnly) {
      return Column(
        children: [
          _PrimaryActionButton(
            label: 'Close',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop(false);
            },
          ),
          const SizedBox(height: 12),
          _SecondaryActionButton(
            label: vm.isDeleting ? 'Deleting...' : 'Delete Run',
            onTap: vm.isDeleting ? null : () => _confirmDelete(context),
          ),
        ],
      );
    }
    return Column(
      children: [
        _PrimaryActionButton(
          label: vm.isSaving ? 'Saving to History...' : 'Done (Saved)',
          onTap: vm.isSaving
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  vm.saveRun(context);
                },
        ),
        const SizedBox(height: 12),
        _SecondaryActionButton(
          label: 'Delete Run',
          onTap: vm.isSaving ? null : () => _confirmDiscard(context, vm),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete run?'),
        content: const Text('This run will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      await vm.deleteRun(context);
    }
  }

  Future<void> _confirmDiscard(BuildContext context, RunSummaryViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text(
          'Your recorded route and stats will be thrown away.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      vm.discardRun(context);
    }
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label, style: AppTextStyles.labelLarge),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SecondaryActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label, style: AppTextStyles.labelLarge),
      ),
    );
  }
}
