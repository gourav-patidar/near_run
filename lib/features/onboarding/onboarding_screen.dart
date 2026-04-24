import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../main.dart' show AppShell;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  int _index = 0;
  double _weightKg = 70;
  double _dailyGoalKm = 5;
  bool _saving = false;

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_index == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name so we can greet you.'),
        ),
      );
      return;
    }
    if (_index == _totalPages - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_index == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await UserPreferencesService.instance.completeOnboarding(
      name: _nameController.text,
      weightKg: _weightKg,
      dailyGoalKm: _dailyGoalKm,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const AppShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(index: _index, total: _totalPages, onBack: _back),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  const _WelcomePage(),
                  _NamePage(controller: _nameController),
                  _WeightPage(
                    value: _weightKg,
                    onChanged: (v) => setState(() => _weightKg = v),
                  ),
                  _DailyGoalPage(
                    value: _dailyGoalKm,
                    onChanged: (v) => setState(() => _dailyGoalKm = v),
                  ),
                ],
              ),
            ),
            _BottomBar(
              index: _index,
              total: _totalPages,
              onNext: _next,
              saving: _saving,
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
                  ? AppColors.onSurfaceVariant.withOpacity(0.3)
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              color: AppColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome to NearRun',
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Track your runs with GPS — no account, no internet required. '
            'Your routes stay on your device.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
          const _FeatureBullet(
            icon: Icons.gps_fixed_rounded,
            title: 'Real GPS tracking',
            body: 'Distance, pace, and elevation recorded in real time.',
          ),
          const SizedBox(height: 14),
          const _FeatureBullet(
            icon: Icons.cloud_off_rounded,
            title: '100% offline',
            body: 'Every run is saved locally. No cloud, no tracking.',
          ),
          const SizedBox(height: 14),
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
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text("What's your name?", style: _titleStyle()),
          const SizedBox(height: 10),
          Text(
            "We'll use it in your greeting and stats.",
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(32)],
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Your first name',
              hintStyle: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Your weight?', style: _titleStyle()),
          const SizedBox(height: 10),
          Text(
            'Used to estimate calories burned. We never share this.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
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
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    'kg',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Daily goal', style: _titleStyle()),
          const SizedBox(height: 10),
          Text(
            'How far would you like to run each day? You can change this later.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
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
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(
                    'km',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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

TextStyle _titleStyle() => AppTextStyles.displaySmall.copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
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
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: Text(
            saving
                ? 'Getting ready…'
                : isLast
                    ? "Let's Run"
                    : 'Continue',
            style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
