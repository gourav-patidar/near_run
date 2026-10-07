import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: const AppTopBar(title: 'Profile'),
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
                  _ProfileHeaderCard(vm: vm),
                  const SizedBox(height: 12),
                  _StreakCard(streakDays: vm.streakDays),
                  const SizedBox(height: 16),
                  _StatsAndChartCard(vm: vm),
                  const SizedBox(height: 16),
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

// ─── Profile Header Card (Small Height, Editable Name) ─────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final ProfileViewModel vm;
  const _ProfileHeaderCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // Gradient Border Avatar
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
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
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1A2A3A),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 26,
                color: Color(0xFF90CAF9),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + Subtitle + Edit Icon
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _editName(context, vm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          vm.name,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.onSurface,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context, ProfileViewModel vm) {
    final controller = TextEditingController(text: vm.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await vm.updateName(controller.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streakDays;
  const _StreakCard({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6F00).withValues(alpha: 0.12),
            const Color(0xFFFF8F00).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6F00).withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFE65100),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT STREAK',
                style: AppTextStyles.chipLabel.copyWith(
                  color: const Color(0xFFE65100),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                streakDays > 0 ? '$streakDays Day Streak 🔥' : '0 Days — Run today to start!',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 18),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          const SizedBox(height: 12),
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
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 13,
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
      height: 110,
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
    const maxHeight = 75.0;
    final height = math.max(maxHeight * bar.intensity, 8.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
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
                      blurRadius: 8,
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
          ],
        ),
        const SizedBox(height: 10),
        if (vm.badges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 26, color: AppColors.onSurfaceVariant),
                const SizedBox(height: 6),
                Text(
                  'Record your first run to unlock badges.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
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
                        padding: const EdgeInsets.only(right: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white70, size: 22),
                const SizedBox(height: 6),
                Text(
                  'DAILY GOAL',
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 10,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.dailyGoalLabel,
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.dailyGoalPercent,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE53935), size: 22),
                const SizedBox(height: 6),
                Text(
                  'AVG BPM',
                  style: AppTextStyles.chipLabel.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vm.avgBpm}',
                  style: AppTextStyles.displaySmall.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE53935),
                    letterSpacing: -0.5,
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
