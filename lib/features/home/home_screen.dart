import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_top_bar.dart';
import '../../core/widgets/route_preview.dart';
import '../active_run/active_run_screen.dart';
import '../run_summary/run_summary_screen.dart';
import 'viewmodel/home_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(),
      body: SafeArea(
        top: false,
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return Column(
              children: [
                // Fixed, Non-Scrollable Hero Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  color: AppColors.background,
                  child: Column(
                    children: [
                      _GreetingSection(vm: vm),
                      const SizedBox(height: 16),
                      _StartRunButton(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActiveRunScreen(),
                            ),
                          );
                          vm.refresh();
                        },
                      ),
                    ],
                  ),
                ),

                // Scrollable Cards Below
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        if (vm.quickTip != null) ...[
                          _QuickTipCard(tip: vm.quickTip!),
                          const SizedBox(height: 16),
                        ],
                        if (vm.lastRun != null)
                          _LastRunCard(run: vm.lastRun!)
                        else
                          const _NoRunsYetCard(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Greeting ─────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final HomeViewModel vm;
  const _GreetingSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          vm.greeting,
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          vm.greetingSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Start Run button (Clean Fixed Size 130px) ───────────────────────────────

class _StartRunButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StartRunButton({required this.onTap});

  @override
  State<_StartRunButton> createState() => _StartRunButtonState();
}

class _StartRunButtonState extends State<_StartRunButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow Ring
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: _glowAnim.value),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Border Ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core Button
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 126,
                    height: 126,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDim],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onPrimary,
                          size: 42,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'START RUN',
                          style: AppTextStyles.startRunLabel.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Quick Tip ────────────────────────────────────────────────────────────────

class _QuickTipCard extends StatelessWidget {
  final QuickTipModel tip;
  const _QuickTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  Text('QUICK TIP', style: AppTextStyles.chipLabel),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tip.title,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                tip.body,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Last Run ─────────────────────────────────────────────────────────────────

class _LastRunCard extends StatelessWidget {
  final RunModel run;
  const _LastRunCard({required this.run});

  String _dateLabel() {
    final now = DateTime.now();
    final runDay = DateTime(run.startTime.year, run.startTime.month, run.startTime.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(runDay).inDays;
    if (diff == 0) return 'Today, ${DateFormat.jm().format(run.startTime)}';
    if (diff == 1) return 'Yesterday, ${DateFormat.jm().format(run.startTime)}';
    return DateFormat('EEE, MMM d • h:mm a').format(run.startTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RunSummaryScreen(run: run, isReadOnly: true),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  children: [
                    RoutePreview(points: run.routePoints),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Last Route',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Run Recap',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                ),
                Text(_dateLabel(), style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    value: run.distanceFormatted,
                    unit: 'KM',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(value: run.durationFormatted, unit: 'TIME'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(
                    value: run.paceFormatted ?? '--',
                    unit: 'PACE',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String unit;
  const _StatChip({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.statValue.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(unit, style: AppTextStyles.statUnit),
        ],
      ),
    );
  }
}

// ─── No runs yet ──────────────────────────────────────────────────────────────

class _NoRunsYetCard extends StatelessWidget {
  const _NoRunsYetCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_run_rounded,
            size: 36,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'No runs yet',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap START RUN above to record your first one.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
