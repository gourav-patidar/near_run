import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:near_run/core/theme/app_colors.dart';
import 'package:near_run/core/theme/app_text_styles.dart';
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
      body: SafeArea(
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
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _TopBar(),
                  const SizedBox(height: 24),
                  _AvatarSection(vm: vm),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _StatsAndChartCard(vm: vm),
                        const SizedBox(height: 28),
                        _BadgesSection(vm: vm),
                        const SizedBox(height: 20),
                        _BottomCardsRow(vm: vm),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
              color: AppColors.inverseSurface,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
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
        // Avatar with gradient ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Gradient ring
            Container(
              width: 120,
              height: 120,
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
            // Avatar bg
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A2A3A),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 64,
                color: Color(0xFF90CAF9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          vm.name,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 30,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),

        // Tier + level
        Text(
          vm.subtitle,
          style: AppTextStyles.labelSmall.copyWith(
            letterSpacing: 1.2,
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
      padding: const EdgeInsets.all(24),
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
          // Total distance + total runs
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
          const SizedBox(height: 24),

          // Weekly intensity header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Intensity',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: AppTextStyles.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bar chart
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
        Text(label, style: AppTextStyles.chipLabel),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.displaySmall.copyWith(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTextStyles.titleMedium.copyWith(
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
      height: 140,
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
    const maxHeight = 100.0;
    final height = math.max(maxHeight * bar.intensity, 10.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: bar.intensity < 0.2
                ? AppColors.surfaceContainerHighest
                : barColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: bar.isToday
                ? [
                    BoxShadow(
                      color: barColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bar.dayLabel,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight:
                bar.isToday ? FontWeight.w800 : FontWeight.w500,
            color:
                bar.isToday ? AppColors.onSurface : AppColors.onSurfaceVariant,
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
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (vm.streakDays > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${vm.streakDays} DAY STREAK',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.badges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 32, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 8),
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
                        padding: const EdgeInsets.only(right: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 10),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 0.8,
              height: 1.4,
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
        // Daily Goal — green card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white70, size: 28),
                const SizedBox(height: 10),
                Text(
                  'DAILY GOAL',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vm.dailyGoalLabel,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.dailyGoalPercent,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Avg BPM — pink card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE53935), size: 28),
                const SizedBox(height: 10),
                Text(
                  'AVG BPM',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${vm.avgBpm}',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE53935),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vm.bpmZoneLabel,
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
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
