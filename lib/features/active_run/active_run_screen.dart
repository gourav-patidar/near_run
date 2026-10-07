import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/models/run_model.dart';
import '../../core/services/gps_tracking_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../run_summary/run_summary_screen.dart';
import 'viewmodel/active_run_viewmodel.dart';

class ActiveRunScreen extends StatelessWidget {
  const ActiveRunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActiveRunViewModel(),
      child: const _ActiveRunView(),
    );
  }
}

class _ActiveRunView extends StatelessWidget {
  const _ActiveRunView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Consumer<ActiveRunViewModel>(
        builder: (context, vm, _) {
          if (vm.isInitializing) return const _InitializingView();
          if (vm.hasError) return _ErrorView(vm: vm);

          return Stack(
            children: [
              const _MapLayer(),
              const _ActiveRunAppBar(),
              const Positioned(top: 100, left: 16, child: _ElevationCard()),
              Positioned(
                right: 16,
                bottom: 310,
                child: _RecenterButton(onTap: vm.recenterMap),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StatsBottomSheet(
                  onStopComplete: (run) => _handleStop(context, run),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleStop(BuildContext context, RunModel? run) async {
    if (!context.mounted) return;
    if (run == null) {
      Navigator.of(context).pop();
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RunSummaryScreen(run: run)),
    );
  }
}

// ─── Initializing / Error states ──────────────────────────────────────────────

class _InitializingView extends StatelessWidget {
  const _InitializingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Getting GPS fix…',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Please allow location permission when prompted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ActiveRunViewModel vm;
  const _ErrorView({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onSurface,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    foregroundColor: AppColors.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
                if (vm.needsAppSettings)
                  ElevatedButton.icon(
                    onPressed: () =>
                        GpsTrackingService.instance.openSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Open Settings'),
                  ),
                if (vm.needsLocationService)
                  ElevatedButton.icon(
                    onPressed: () => GpsTrackingService.instance
                        .openLocationServiceSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                    label: const Text('Turn On GPS'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Map layer ────────────────────────────────────────────────────────────────

class _MapLayer extends StatelessWidget {
  const _MapLayer();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) {
        return Stack(
          children: [
            const _OfflineMapBackground(),
            FlutterMap(
              mapController: vm.mapController,
              options: MapOptions(
                initialCenter:
                    vm.currentPosition ?? const LatLng(0.0, 0.0),
                initialZoom: 16.0,
                minZoom: 3.0,
                maxZoom: 19.0,
                onMapReady: () {
                  if (vm.currentPosition != null) {
                    vm.mapController.move(vm.currentPosition!, 16.0);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.near_run',
                  errorTileCallback: (_, __, ___) {},
                ),
                if (vm.routeLatLngs.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: vm.routeLatLngs,
                        strokeWidth: 5.0,
                        color: AppColors.primary,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),
                if (vm.currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: vm.currentPosition!,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OfflineMapBackground extends StatelessWidget {
  const _OfflineMapBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5ECE9),
      child: CustomPaint(
        painter: _GridPatternPainter(),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _ActiveRunAppBar extends StatelessWidget {
  const _ActiveRunAppBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Text(
                'NearRun',
                style: AppTextStyles.brandTitle.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.6,
                ),
              ),
              const Spacer(),
              Consumer<ActiveRunViewModel>(
                builder: (_, vm, __) => _StatusBadge(
                  icon: vm.isRunning
                      ? Icons.radio_button_checked_rounded
                      : Icons.pause_circle_outline,
                  label: vm.isRunning ? 'LIVE' : 'PAUSED',
                  color: vm.isRunning ? AppColors.primary : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurface,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.onSurface, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─── Elevation card ───────────────────────────────────────────────────────────

class _ElevationCard extends StatelessWidget {
  const _ElevationCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
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
                Text(
                  'ELEVATION',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.primary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${vm.elevationMeters}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' m',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.elevationProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerLow,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryContainer,
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

// ─── Recenter button ──────────────────────────────────────────────────────────

class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Stats sheet ──────────────────────────────────────────────────────────────

class _StatsBottomSheet extends StatelessWidget {
  final void Function(RunModel?) onStopComplete;
  const _StatsBottomSheet({required this.onStopComplete});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DISTANCE', style: AppTextStyles.chipLabel.copyWith(fontSize: 10)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          vm.distanceWhole,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          vm.distanceDecimal,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'km',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                _PausePlayButton(
                  vm: vm,
                  onStop: () async {
                    final run = await vm.stopAndBuildRun();
                    onStopComplete(run);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _RunMetric(
                  icon: Icons.speed_rounded,
                  label: 'PACE',
                  value: vm.paceFormatted,
                  unit: '/km',
                ),
                const SizedBox(width: 24),
                _RunMetric(
                  icon: Icons.timer_outlined,
                  label: 'TIME',
                  value: vm.durationFormatted,
                  unit: '',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SlideToStopTrack(
              onStop: () async {
                final run = await vm.stopAndBuildRun();
                onStopComplete(run);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PausePlayButton extends StatelessWidget {
  final ActiveRunViewModel vm;
  final VoidCallback onStop;
  const _PausePlayButton({required this.vm, required this.onStop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        vm.togglePause();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        onStop();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(vm.isRunning),
            color: AppColors.primary,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _SlideToStopTrack extends StatefulWidget {
  final VoidCallback onStop;
  const _SlideToStopTrack({required this.onStop});

  @override
  State<_SlideToStopTrack> createState() => _SlideToStopTrackState();
}

class _SlideToStopTrackState extends State<_SlideToStopTrack> {
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const knobSize = 44.0;
        final maxDragDistance = trackWidth - knobSize - 8;

        return Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragValue * 1.5)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SLIDE TO FINISH & SAVE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.double_arrow_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4 + (_dragValue * maxDragDistance),
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      final delta = details.primaryDelta! / maxDragDistance;
                      _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragValue >= 0.75) {
                      setState(() => _dragValue = 1.0);
                      HapticFeedback.heavyImpact();
                      widget.onStop();
                    } else {
                      setState(() => _dragValue = 0.0);
                    }
                  },
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _RunMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.chipLabel.copyWith(fontSize: 9)),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
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
