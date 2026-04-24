import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Consumer<HistoryViewModel>(
                builder: (_, vm, __) {
                  if (vm.isLoading) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (vm.isEmpty) return const _EmptyState();
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.refresh,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: _HistoryHeading()),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverList.separated(
                            itemCount: vm.runs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (ctx, i) => _RunCard(
                              run: vm.runs[i],
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RunSummaryScreen(
                                      run: vm.runs[i],
                                      isReadOnly: true,
                                    ),
                                  ),
                                );
                                // Reload in case the user deleted the run from Summary.
                                vm.refresh();
                              },
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
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

class _HistoryHeading extends StatelessWidget {
  const _HistoryHeading();

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
                  Text(
                    _dateLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatItem(
                        label: 'DIST',
                        value: run.distanceFormatted,
                        unit: 'km',
                        valueColor: AppColors.primary,
                      ),
                      const SizedBox(width: 28),
                      _StatItem(
                        label: 'TIME',
                        value: run.durationFormatted,
                        unit: '',
                        valueColor: AppColors.onSurface,
                      ),
                      const SizedBox(width: 28),
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
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: SizedBox(
                height: 160,
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
        Text(label, style: AppTextStyles.chipLabel),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                fontSize: 22,
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
