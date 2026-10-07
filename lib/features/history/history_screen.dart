import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/route_preview.dart';
import '../run_summary/run_summary_screen.dart';
import 'viewmodel/history_viewmodel.dart';

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

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'History'),
      body: SafeArea(
        top: false,
        child: Consumer<HistoryViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (vm.isEmpty) return const _EmptyState();
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                itemCount: vm.runs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (ctx, i) {
                  final run = vm.runs[i];
                  return Dismissible(
                    key: Key('run_${run.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      HapticFeedback.mediumImpact();
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Run?'),
                          content: const Text(
                            'Are you sure you want to delete this run permanently?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      HapticFeedback.heavyImpact();
                      if (run.id != null) {
                        await vm.deleteRun(run.id!);
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: _RunCard(
                      run: run,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RunSummaryScreen(
                              run: run,
                              isReadOnly: true,
                            ),
                          ),
                        );
                        vm.refresh();
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  final RunModel run;
  final VoidCallback onTap;
  const _RunCard({required this.run, required this.onTap});

  String get _dateLabel {
    final now = DateTime.now();
    final runDay = DateTime(run.startTime.year, run.startTime.month, run.startTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(runDay).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('MMM d, y').format(run.startTime).toUpperCase();
  }

  String get _title {
    final h = run.startTime.hour;
    if (h < 10) return 'Morning Run';
    if (h < 14) return 'Midday Run';
    if (h < 18) return 'Afternoon Run';
    if (h < 22) return 'Evening Run';
    return 'Night Run';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _dateLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatItem(
                        label: 'DIST',
                        value: run.distanceFormatted,
                        unit: 'km',
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(width: 20),
                      _StatItem(
                        label: 'TIME',
                        value: run.durationFormatted,
                        unit: '',
                        valueColor: AppColors.onSurface,
                      ),
                      const SizedBox(width: 20),
                      _StatItem(
                        label: 'PACE',
                        value: run.paceFormatted ?? '--',
                        unit: '/km',
                        valueColor: AppColors.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: RoutePreview(points: run.routePoints),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 9)),
        const SizedBox(height: 1),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.3,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ],
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_run_rounded,
            size: 44,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No runs yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your first run from the home screen',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
