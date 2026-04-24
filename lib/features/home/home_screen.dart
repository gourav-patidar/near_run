import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: vm.refresh,
            child: ListView(
              padding: const EdgeInsets.only(
                top: 100,
                left: 20,
                right: 20,
                bottom: 120,
              ),
              children: [
                _GreetingSection(vm: vm),
                const SizedBox(height: 32),
                _StartRunButton(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveRunScreen(),
                      ),
                    );
                    // Reload last-run card when we come back.
                    vm.refresh();
                  },
                ),
                const SizedBox(height: 36),
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
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 68 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.outlineVariant.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryContainer,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text('NearRun', style: AppTextStyles.brandTitle),
              ],
            ),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vm.greeting, style: AppTextStyles.headlineLarge),
        const SizedBox(height: 6),
        Text(vm.greetingSubtitle, style: AppTextStyles.greetingSubtitle),
      ],
    );
  }
}

// ─── Start Run button ─────────────────────────────────────────────────────────

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

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.2, end: 0.45).animate(
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
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(_glowAnim.value),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: _scaleAnim.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDim],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.onPrimary,
                          size: 64,
                        ),
                        const SizedBox(height: 4),
                        Text('START RUN', style: AppTextStyles.startRunLabel),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.onSecondaryContainer,
                      size: 22,
                    ),
                  ),
                  Text('QUICK TIP', style: AppTextStyles.chipLabel),
                ],
              ),
              const SizedBox(height: 16),
              Text(tip.title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 6),
              Text(tip.body, style: AppTextStyles.bodyMedium),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  children: [
                    RoutePreview(points: run.routePoints),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Last Route',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last Run Recap', style: AppTextStyles.titleMedium),
                Text(_dateLabel(), style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatChip(
                    value: run.distanceFormatted,
                    unit: 'KM',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatChip(value: run.durationFormatted, unit: 'TIME'),
                ),
                const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statValue),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_run_rounded,
            size: 44,
            color: AppColors.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text('No runs yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
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
