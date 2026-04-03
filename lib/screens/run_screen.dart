import 'package:flutter/material.dart';
import 'package:near_run/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:near_run/providers/run_provider.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRun();
  }

  Future<void> _initializeRun() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    try {
      await context.read<RunProvider>().startRun();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission required: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final provider = context.read<RunProvider>();
        if (provider.status == RunStatus.running || 
            provider.status == RunStatus.paused) {
          _showExitDialog(provider);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: _isInitialized 
            ? Consumer<RunProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      _buildHeader(provider),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              _buildMainStats(provider),
                              const SizedBox(height: 40),
                              _buildSecondaryStats(provider),
                              const Spacer(),
                              _buildControls(provider),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
            : _buildLoadingScreen(),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Initializing GPS...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(RunProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => _showExitDialog(provider),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Current Run',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gps_fixed, 
                      color: Colors.white, 
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      provider.status == RunStatus.running 
                        ? 'GPS Active' 
                        : 'GPS Paused',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainStats(RunProvider provider) {
    return Column(
      children: [
        Text(
          'DISTANCE',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider.distance.toStringAsFixed(2),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        Text(
          'kilometers',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'DURATION',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          provider.formattedDuration,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 48,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryStats(RunProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            '🔥',
            '${provider.calories}',
            'kcal',
          ),
          _buildStatCard(
            '⚡',
            provider.currentSpeed.toStringAsFixed(1),
            'km/hr',
          ),
          _buildStatCard(
            '📊',
            provider.avgSpeed.toStringAsFixed(1),
            'avg km/hr',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(RunProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (provider.status == RunStatus.running)
            _buildControlButton(
              icon: Icons.pause_rounded,
              label: 'Pause',
              color: Colors.orange,
              onPressed: () => provider.pauseRun(),
            )
          else if (provider.status == RunStatus.paused)
            _buildControlButton(
              icon: Icons.play_arrow_rounded,
              label: 'Resume',
              color: Colors.green,
              onPressed: () => provider.resumeRun(),
            ),
          _buildControlButton(
            icon: Icons.stop_rounded,
            label: 'Finish',
            color: Colors.red,
            onPressed: () => _showFinishDialog(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          borderRadius: BorderRadius.circular(35),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(35),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Icon(icon, color: Colors.white, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showExitDialog(RunProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Exit Run?'),
          ],
        ),
        content: const Text(
          'Your progress will be lost if you exit now without finishing.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await provider.stopRun();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close run screen
              }
            },
            child: const Text(
              'Exit',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(RunProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.flag_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            const Text('Finish Run?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Great job! Here\'s your summary:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    '🏃 Distance', 
                    '${provider.distance.toStringAsFixed(2)} km'
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    '⏱️ Duration', 
                    provider.formattedDuration
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    '🔥 Calories', 
                    '${provider.calories} kcal'
                  ),
                  const Divider(height: 16),
                  _buildSummaryRow(
                    '📊 Avg Speed', 
                    '${provider.avgSpeed.toStringAsFixed(1)} km/hr'
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continue Running',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.stopRun();
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close run screen
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Run saved successfully! 🎉',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Finish & Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}