import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../home/viewmodel/home_viewmodel.dart';

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

// ─── Root View ────────────────────────────────────────────────────────────────

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
                _StartRunButton(onTap: vm.onStartRunTapped),
                const SizedBox(height: 36),
                if (vm.quickTip != null) ...[
                  _QuickTipCard(tip: vm.quickTip!),
                  const SizedBox(height: 16),
                ],
                if (vm.weather != null) ...[
                  _WeatherCard(weather: vm.weather!),
                  const SizedBox(height: 16),
                ],
                if (vm.lastRun != null) _LastRunCard(run: vm.lastRun!),
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
              right: 12,
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
                // Avatar
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

                // Brand title
                Text('NearRun', style: AppTextStyles.brandTitle),

                const Spacer(),

                // Notification bell
                Consumer<HomeViewModel>(
                  builder: (_, vm, __) => IconButton(
                    onPressed: vm.onNotificationTapped,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Greeting Section ─────────────────────────────────────────────────────────

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

// ─── Start Run Button ─────────────────────────────────────────────────────────

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

    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnim = Tween<double>(
      begin: 0.2,
      end: 0.45,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                // Ambient glow rings
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

                // Outer ring (subtle)
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

                // Main button
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

// ─── Quick Tip Card ───────────────────────────────────────────────────────────

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
                  // Icon badge
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

                  // "QUICK TIP" tag
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

// ─── Weather Card ─────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final WeatherModel weather;
  const _WeatherCard({required this.weather});

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
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: temp + city
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_cloudy_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${weather.temperatureCelsius.toStringAsFixed(0)}°C',
                    style: AppTextStyles.headlineSmall,
                  ),
                ],
              ),
              Text(weather.city, style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom row: wind + humidity
          Row(
            children: [
              _WeatherDetail(icon: Icons.air_rounded, label: weather.windSpeed),
              const SizedBox(width: 20),
              _WeatherDetail(
                icon: Icons.water_drop_outlined,
                label: '${weather.humidityPercent}% Humidity',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WeatherDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ─── Last Run Recap Card ──────────────────────────────────────────────────────

class _LastRunCard extends StatelessWidget {
  final LastRunModel run;
  const _LastRunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Map thumbnail placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              color: AppColors.primaryContainer.withOpacity(0.3),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder route lines
                  CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _RoutePainter(),
                  ),
                  // Map overlay label
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
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title + date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last Run Recap', style: AppTextStyles.titleMedium),
              Text(run.dateLabel, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  value: run.distanceKm.toStringAsFixed(1),
                  unit: 'KM',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(value: run.duration, unit: 'TIME'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(value: run.pace, unit: 'PACE'),
              ),
            ],
          ),
        ],
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

// ─── Route Painter (map placeholder) ─────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.6)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.15,
        size.width * 0.7,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.5,
        size.width * 0.75,
        size.height * 0.8,
        size.width * 0.4,
        size.height * 0.8,
      )
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.8,
        size.width * 0.12,
        size.height * 0.75,
        size.width * 0.15,
        size.height * 0.6,
      );

    // Draw faint fill
    final fillPaint = Paint()
      ..color = AppColors.primaryContainer.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Start dot
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.6),
      6,
      Paint()..color = AppColors.primary,
    );

    // End dot
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.35),
      6,
      Paint()
        ..color = AppColors.surfaceContainerLowest
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.35),
      6,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
