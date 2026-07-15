import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'glass_card.dart';
import 'quest_celebration.dart';

class DailyQuestsWidget extends StatefulWidget {
  const DailyQuestsWidget({super.key});

  @override
  State<DailyQuestsWidget> createState() => _DailyQuestsWidgetState();
}

class _DailyQuestsWidgetState extends State<DailyQuestsWidget> {
  List<dynamic> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getTodayQuests();
    if (mounted) {
      setState(() {
        if (data != null && data['quests'] != null) {
          _quests = data['quests'];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (_quests.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISIONES DIARIAS',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ..._quests.map((quest) => _buildQuestCard(quest)).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestCard(Map<String, dynamic> quest) {
    final description = quest['description'] ?? 'Misión';
    final target = quest['targetValue'] is num ? (quest['targetValue'] as num).toInt() : 1;
    final current = quest['currentValue'] is num ? (quest['currentValue'] as num).toInt() : 0;
    
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  color: progress >= 1.0 ? Colors.green : AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              if (progress >= 1.0)
                ElevatedButton(
                  onPressed: () {
                    QuestCelebration.show(context, coinsEarned: quest['rewardCoins'] ?? 10);
                    // Optionally call an API here to actually claim the chest
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Reclamar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                )
              else
                Text(
                  '$current / $target',
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
