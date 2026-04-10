import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:near_run/core/theme/app_colors.dart';
import 'package:near_run/core/theme/app_text_styles.dart';
import 'package:near_run/features/active_run/viewmodel/active_run_viewmodel.dart';
import 'package:near_run/core/services/gps_tracking_service.dart';
import 'package:provider/provider.dart';

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

// ─── Root View ────────────────────────────────────────────────────────────────

class _ActiveRunView extends StatelessWidget {
  const _ActiveRunView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: Consumer<ActiveRunViewModel>(
        builder: (context, vm, _) {
          // Show loading while initializing
          if (vm.isIdle) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Initializing GPS...',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Please allow location permissions when prompted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Show error if permission denied or GPS failed
          if (vm.isStopped && vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerHigh,
                            foregroundColor: AppColors.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Go Back'),
                        ),
                        if (vm.errorMessage!.contains('settings'))
                          const SizedBox(width: 12),
                        if (vm.errorMessage!.contains('settings'))
                          ElevatedButton.icon(
                            onPressed: () async {
                              await GpsTrackingService.instance.openSettings();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            label: const Text('Open Settings'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // Normal running UI
          return Stack(
            children: [
              // ── Full screen map ────────────────────────────────────────────────
              const _MapPlaceholder(),

              // ── Top app bar ───────────────────────────────────────────────────
              const _ActiveRunAppBar(),

              // ── Elevation overlay (top-left) ──────────────────────────────────
              const Positioned(top: 100, left: 20, child: _ElevationCard()),

              // ── Re-center button (right) ──────────────────────────────────────
              Positioned(
                right: 20,
                bottom: 360,
                child: _RecenterButton(onTap: () => vm.recenterMap()),
              ),

              // ── Bottom stats sheet ────────────────────────────────────────────
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StatsBottomSheet(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Map Placeholder ──────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) {
        return FlutterMap(
          mapController: vm.mapController,
          options: MapOptions(
            initialCenter:
                vm.currentPosition ??
                const LatLng(37.7749, -122.4194), // SF default
            initialZoom: 16.0,
            minZoom: 12.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // OpenStreetMap tiles (free, no API key needed)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.gourav.near_run',
              tileProvider: NetworkTileProvider(),
            ),

            // Route polyline
            if (vm.routeLatLngs.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: vm.routeLatLngs,
                    strokeWidth: 6.0,
                    color: AppColors.primary,
                    borderColor: Colors.white,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

            // Current position marker
            if (vm.currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: vm.currentPosition!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
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
        );
      },
    );
  }
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────

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
              // Hamburger
              _GlassIconButton(
                icon: Icons.menu_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),

              // Logo
              Text(
                'near_run',
                style: AppTextStyles.brandTitle.copyWith(
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),

              // STRONG badge
              _StatusBadge(
                icon: Icons.radio_button_checked_rounded,
                label: 'STRONG',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: AppColors.outlineVariant),
              const SizedBox(width: 8),

              // ON badge
              _StatusBadge(
                icon: Icons.local_fire_department_outlined,
                label: 'ON',
                color: Colors.orange,
              ),
              const SizedBox(width: 12),

              // Avatar
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 1,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.onSurface, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Elevation Card ───────────────────────────────────────────────────────────

class _ElevationCard extends StatelessWidget {
  const _ElevationCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
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
                Text(
                  'ELEVATION',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${vm.elevationMeters}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 36,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextSpan(text: ' m', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Elevation bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: vm.elevationProgress,
                    minHeight: 10,
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

// ─── Recenter Button ──────────────────────────────────────────────────────────

class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.onSurface,
          size: 22,
        ),
      ),
    );
  }
}

// ─── Stats Bottom Sheet ───────────────────────────────────────────────────────

class _StatsBottomSheet extends StatelessWidget {
  const _StatsBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveRunViewModel>(
      builder: (_, vm, __) => Container(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Distance row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DISTANCE', style: AppTextStyles.chipLabel),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          vm.distanceWhole,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -3,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          vm.distanceDecimal,
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -3,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'km',
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),

                // ── Pause/Play button ──────────────────────────────────────
                _PausePlayButton(vm: vm),
              ],
            ),

            // ── Hold to stop ──────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onLongPress: () async {
                  await vm.stopRun();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                onLongPressStart: (_) {
                  // Visual feedback that press is registered
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'HOLD TO STOP',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Pace + Duration row ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _RunMetric(
                    icon: Icons.speed_rounded,
                    label: 'CURRENT PACE',
                    value: vm.paceFormatted,
                    unit: '/km',
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.outlineVariant,
                ),
                Expanded(
                  child: _RunMetric(
                    icon: Icons.timer_outlined,
                    label: 'DURATION',
                    value: vm.durationFormatted,
                    unit: '',
                    align: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Heart Rate Zone card ──────────────────────────────────────
            _HeartRateZoneCard(vm: vm),
          ],
        ),
      ),
    );
  }
}

// ─── Pause / Play Button ──────────────────────────────────────────────────────

class _PausePlayButton extends StatelessWidget {
  final ActiveRunViewModel vm;
  const _PausePlayButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: vm.togglePause,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(vm.isRunning),
            color: AppColors.primary,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ─── Run Metric ───────────────────────────────────────────────────────────────

class _RunMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final TextAlign align;

  const _RunMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = align == TextAlign.right;
    return Padding(
      padding: EdgeInsets.only(left: isRight ? 20 : 0, right: isRight ? 0 : 20),
      child: Column(
        crossAxisAlignment: isRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.chipLabel),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: isRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(unit, style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Heart Rate Zone Card ─────────────────────────────────────────────────────

class _HeartRateZoneCard extends StatelessWidget {
  final ActiveRunViewModel vm;
  const _HeartRateZoneCard({required this.vm});

  // Colors per zone segment
  static const _segmentColors = [
    Color(0xFF80D8FF), // Z1 blue
    Color(0xFF69F0AE), // Z2 green
    Color(0xFF48E5D0), // Z3 teal
    AppColors.primaryContainer, // Z4 primary teal
    Color(0xFFFF7043), // Z5 red
  ];

  @override
  Widget build(BuildContext context) {
    final zone = vm.heartRateZone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Heart icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // BPM
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vm.heartRateBpm}',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 22,
                ),
              ),
              Text('BPM', style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(width: 16),

          // Zone bar segments
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ZONE ${zone.number}: ${zone.label}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final filled = i < vm.filledZoneSegments;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        height: 6,
                        decoration: BoxDecoration(
                          color: filled
                              ? _segmentColors[i]
                              : AppColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
