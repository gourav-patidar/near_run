import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:near_run/core/theme/app_colors.dart';
import 'package:near_run/core/theme/app_text_styles.dart';
import 'package:near_run/core/widgets/app_top_bar.dart';
import 'package:near_run/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel(),
      child: const _ProfileView(),
    );
  }
}

// ─── Root View ────────────────────────────────────────────────────────────────

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      body: SafeArea(
        top: false,
        child: Consumer<ProfileViewModel>(
          builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  _AvatarSection(vm: vm),
                  const SizedBox(height: 24),
                  _StatsAndChartCard(vm: vm),
                  const SizedBox(height: 20),
                  _BadgesSection(vm: vm),
                  const SizedBox(height: 16),
                  _BottomCardsRow(vm: vm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Avatar Section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  final ProfileViewModel vm;
  const _AvatarSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF48E5D0),
                    Color(0xFF40C4FF),
                    Color(0xFFCE93D8),
                    Color(0xFFFF8A65),
                    Color(0xFF48E5D0),
                  ],
                ),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A2A3A),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 48,
                color: Color(0xFF90CAF9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          vm.name,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          vm.subtitle,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            letterSpacing: 1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Stats + Chart Card ───────────────────────────────────────────────────────

class _StatsAndChartCard extends StatelessWidget {
  final ProfileViewModel vm;
  const _StatsAndChartCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatLabel(
                  label: 'TOTAL DISTANCE',
                  value: vm.totalDistanceFormatted,
                  unit: 'km',
                ),
              ),
              Expanded(
                child: _StatLabel(
                  label: 'TOTAL RUNS',
                  value: '${vm.totalRuns}',
                  unit: 'sess.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Intensity',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeeklyBarChart(bars: vm.weeklyBars),
        ],
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatLabel(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.displaySmall.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 14,
                color: AppColors.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Weekly Bar Chart ─────────────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<WeeklyBarModel> bars;
  const _WeeklyBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: bars.map((bar) => _Bar(bar: bar)).toList(),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final WeeklyBarModel bar;
  const _Bar({required this.bar});

  Color get barColor {
    try {
      final hex = bar.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxHeight = 85.0;
    final height = math.max(maxHeight * bar.intensity, 8.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 26,
          height: height,
          decoration: BoxDecoration(
            color: bar.intensity < 0.2
                ? AppColors.surfaceContainerHighest
                : barColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: bar.isToday
                ? [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          bar.dayLabel,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            fontWeight: bar.isToday ? FontWeight.w800 : FontWeight.w500,
            color: bar.isToday ? AppColors.onSurface : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Badges Section ───────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final ProfileViewModel vm;
  const _BadgesSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Earned Badges',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (vm.streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${vm.streakDays} DAY STREAK',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 10,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.badges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 28, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 6),
                Text(
                  'Record your first run to unlock badges.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Row(
            children: vm.badges
                .map((b) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _BadgeChip(badge: b),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeChip({required this.badge});

  Color get bgColor {
    try {
      final hex = badge.bgColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.surfaceContainerLow;
    }
  }

  IconData get icon {
    switch (badge.icon) {
      case BadgeIcon.fastStart:
        return Icons.bolt_rounded;
      case BadgeIcon.hillClimber:
        return Icons.landscape_rounded;
      case BadgeIcon.sevenDayStreak:
        return Icons.calendar_month_rounded;
      case BadgeIcon.nightOwl:
        return Icons.nightlight_rounded;
      case BadgeIcon.speedDemon:
        return Icons.speed_rounded;
    }
  }

  Color get iconColor {
    switch (badge.icon) {
      case BadgeIcon.fastStart:
        return const Color(0xFFE53935);
      case BadgeIcon.hillClimber:
        return AppColors.primary;
      case BadgeIcon.sevenDayStreak:
        return const Color(0xFF1E88E5);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 10,
              color: AppColors.onSurface,
              letterSpacing: 0.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Cards Row ─────────────────────────────────────────────────────────

class _BottomCardsRow extends StatelessWidget {
  final ProfileViewModel vm;
  const _BottomCardsRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white70, size: 24),
                const SizedBox(height: 8),
                Text(
                  'DAILY GOAL',
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 10,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vm.dailyGoalLabel,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.dailyGoalPercent,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE53935), size: 24),
                const SizedBox(height: 8),
                Text(
                  'AVG BPM',
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vm.avgBpm}',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE53935),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vm.bpmZoneLabel,
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 9,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
