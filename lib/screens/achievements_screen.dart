import 'package:flutter/material.dart';
import 'package:near_run/utils/app_colors.dart';

class Achievement {
  final String title;
  final String description;
  final String emoji;
  final bool unlocked;
  final int progress;
  final int target;

  Achievement({
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlocked,
    required this.progress,
    required this.target,
  });
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      Achievement(
        title: 'First Steps',
        description: 'Complete your first run',
        emoji: '👟',
        unlocked: true,
        progress: 1,
        target: 1,
      ),
      Achievement(
        title: '5K Runner',
        description: 'Run 5 kilometers in one session',
        emoji: '🏃',
        unlocked: true,
        progress: 5,
        target: 5,
      ),
      Achievement(
        title: '10K Champion',
        description: 'Run 10 kilometers in one session',
        emoji: '🏅',
        unlocked: true,
        progress: 10,
        target: 10,
      ),
      Achievement(
        title: 'Marathon Ready',
        description: 'Run 42 kilometers total',
        emoji: '🎯',
        unlocked: false,
        progress: 29,
        target: 42,
      ),
      Achievement(
        title: 'Weekly Warrior',
        description: 'Run 50km in one week',
        emoji: '⚡',
        unlocked: false,
        progress: 35,
        target: 50,
      ),
      Achievement(
        title: 'Calorie Crusher',
        description: 'Burn 5000 calories total',
        emoji: '🔥',
        unlocked: false,
        progress: 1980,
        target: 5000,
      ),
      Achievement(
        title: 'Consistency King',
        description: 'Run for 7 consecutive days',
        emoji: '👑',
        unlocked: false,
        progress: 3,
        target: 7,
      ),
      Achievement(
        title: 'Century Club',
        description: 'Complete 100 total runs',
        emoji: '💯',
        unlocked: false,
        progress: 3,
        target: 100,
      ),
    ];

    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(unlockedCount, achievements.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  return _buildAchievementCard(achievements[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int unlocked, int total) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unlocked/$total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: unlocked / total,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${((unlocked / total) * 100).toInt()}% completed',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: achievement.unlocked
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: achievement.unlocked
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 36,
                  color: achievement.unlocked ? null : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: achievement.unlocked ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (!achievement.unlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress / achievement.target,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.progress}/${achievement.target}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.unlocked)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}