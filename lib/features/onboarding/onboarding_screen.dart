import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart' show AppShell;

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _totalPages = 4;

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();
    final nameController = TextEditingController();

    final currentIndex = ValueNotifier<int>(0);
    final weightKg = ValueNotifier<double>(70);
    final dailyGoalKm = ValueNotifier<double>(5);
    final isSaving = ValueNotifier<bool>(false);

    void next() {
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      final idx = currentIndex.value;

      if (idx == 1 && nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name so we can greet you.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (idx == _totalPages - 1) {
        if (isSaving.value) return;
        isSaving.value = true;
        UserPreferencesService.instance
            .completeOnboarding(
              name: nameController.text,
              weightKg: weightKg.value,
              dailyGoalKm: dailyGoalKm.value,
            )
            .then((_) {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 320),
              pageBuilder: (_, __, ___) => const AppShell(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        });
        return;
      }

      pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    void back() {
      HapticFeedback.lightImpact();
      if (currentIndex.value == 0) return;
      pageController.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (_, idx, __) => _Header(
                index: idx,
                total: _totalPages,
                onBack: back,
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => currentIndex.value = i,
                children: [
                  const _WelcomePage(),
                  _NamePage(controller: nameController),
                  ValueListenableBuilder<double>(
                    valueListenable: weightKg,
                    builder: (_, w, __) => _WeightPage(
                      value: w,
                      onChanged: (v) => weightKg.value = v,
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: dailyGoalKm,
                    builder: (_, g, __) => _DailyGoalPage(
                      value: g,
                      onChanged: (v) => dailyGoalKm.value = v,
                    ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (_, idx, __) => ValueListenableBuilder<bool>(
                valueListenable: isSaving,
                builder: (_, saving, __) => _BottomBar(
                  index: idx,
                  total: _totalPages,
                  onNext: next,
                  saving: saving,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onBack;
  const _Header({
    required this.index,
    required this.total,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: index == 0 ? null : onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: index == 0
                  ? AppColors.onSurfaceVariant.withValues(alpha: 0.3)
                  : AppColors.onSurface,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (index + 1) / total,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${index + 1} / $total',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome ──────────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to NearRun',
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your runs with GPS — no account, no internet required. '
            'Your routes stay on your device.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const _FeatureBullet(
            icon: Icons.gps_fixed_rounded,
            title: 'Real GPS tracking',
            body: 'Distance, pace, and elevation recorded in real time.',
          ),
          const SizedBox(height: 12),
          const _FeatureBullet(
            icon: Icons.cloud_off_rounded,
            title: '100% offline',
            body: 'Every run is saved locally. No cloud, no tracking.',
          ),
          const SizedBox(height: 12),
          const _FeatureBullet(
            icon: Icons.insights_rounded,
            title: 'Your progress',
            body: 'History, weekly intensity, streaks, badges you earn.',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Name ─────────────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  const _NamePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text("What's your name?", style: _titleStyle()),
          const SizedBox(height: 6),
          Text(
            "We'll use it in your greeting and stats.",
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Your first name',
              hintStyle: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Weight ───────────────────────────────────────────────────────────────────

class _WeightPage extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _WeightPage({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Your weight?', style: _titleStyle()),
          const SizedBox(height: 6),
          Text(
            'Used to estimate calories burned. We never share this.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.round().toString(),
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'kg',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: 35,
            max: 150,
            divisions: 115,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─── Daily goal ───────────────────────────────────────────────────────────────

class _DailyGoalPage extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _DailyGoalPage({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Daily goal', style: _titleStyle()),
          const SizedBox(height: 6),
          Text(
            'How far would you like to run each day? You can change this later.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'km',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: 1,
            max: 21,
            divisions: 200,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

TextStyle _titleStyle() => AppTextStyles.headlineMedium.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: AppColors.onSurface,
      letterSpacing: -0.5,
    );

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int index;
  final int total;
  final VoidCallback onNext;
  final bool saving;
  const _BottomBar({
    required this.index,
    required this.total,
    required this.onNext,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            saving
                ? 'Getting ready…'
                : isLast
                    ? "Let's Run"
                    : 'Continue',
            style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
          ),
        ),
      ),
    );
  }
}
