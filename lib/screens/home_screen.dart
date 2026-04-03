import 'package:flutter/material.dart';
import 'package:near_run/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:near_run/providers/run_provider.dart';
import 'package:near_run/screens/run_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<RunProvider>().loadRunHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekGoalCard(),
                    const SizedBox(height: 16),
                    _buildSwipeToStartCard(),
                    const SizedBox(height: 24),
                    _buildRecentActivitySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              'A',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Andrew',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Beginner',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white, size: 26),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekGoalCard() {
    return Consumer<RunProvider>(
      builder: (context, provider, _) {
        const totalKm = 50.0;
        final kmDone = provider.weeklyDistance;
        final progress = (kmDone / totalKm).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
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
                  Row(
                    children: [
                      Text(
                        'Week goal ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${totalKm.toInt()} km',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${kmDone.toStringAsFixed(1)} km done',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(totalKm - kmDone).toStringAsFixed(1)} km left',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwipeToStartCard() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to run?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Swipe to start tracking',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SwipeToStartButton(
              onSwipeComplete: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RunScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Consumer<RunProvider>(
      builder: (context, provider, _) {
        if (provider.runHistory.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.directions_run, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No runs yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first run to see it here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all activities
                  },
                  child: Text(
                    'All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...provider.runHistory.take(5).map((run) => _buildActivityCard(run)),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(RunData run) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: RoutePathPainter(AppColors.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d').format(run.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${run.distance.toStringAsFixed(2)} km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${run.calories} kcal  •  ${run.avgSpeed.toStringAsFixed(1)} km/hr',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class SwipeToStartButton extends StatefulWidget {
  final VoidCallback onSwipeComplete;

  const SwipeToStartButton({super.key, required this.onSwipeComplete});

  @override
  State<SwipeToStartButton> createState() => _SwipeToStartButtonState();
}

class _SwipeToStartButtonState extends State<SwipeToStartButton> {
  double _dragPosition = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final maxDrag = MediaQuery.of(context).size.width - 120;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'Swipe to start run',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: _dragPosition,
            top: 4,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_dragPosition > maxDrag * 0.8) {
                  widget.onSwipeComplete();
                }
                setState(() {
                  _dragPosition = 0.0;
                  _isDragging = false;
                });
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoutePathPainter extends CustomPainter {
  final Color color;

  RoutePathPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.5,
      size.width * 0.3,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.95,
      size.width * 0.6,
      size.height * 0.7,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}