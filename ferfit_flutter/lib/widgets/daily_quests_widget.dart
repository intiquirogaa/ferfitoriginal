import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'glass_card.dart';
import 'quest_celebration.dart';
import '../screens/quests_screen.dart';
import '../screens/challenge_proof_screen.dart';
import '../screens/villain_battle_screen.dart';

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
          _quests = List.from(data['quests']);
        }
        _isLoading = false;
      });
      if (data != null && data['notifications'] is List) {
        final notifs = (data['notifications'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        await NotificationService.instance.scheduleChallengeNotifications(notifs);
      }
    }
  }

  Future<void> _claim(Map quest) async {
    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
    if (id <= 0) return;
    final res = await ApiService.claimQuest(id);
    if (!mounted) return;
    if (res != null && res['error'] == null) {
      QuestCelebration.show(
        context,
        coinsEarned: (res['coins'] is num)
            ? (res['coins'] as num).toInt()
            : (quest['rewardCoins'] ?? 10),
      );
      await _loadQuests();
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
                'MISIONES DEL COACH',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuestsScreen()),
                  ).then((_) => _loadQuests());
                },
                child: Text(
                  'Ver todas',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Feo planifica desafíos diarios, combates y evidencia de técnica.',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ..._quests.map((quest) => _buildQuestCard(quest)).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestCard(dynamic raw) {
    final quest = Map<String, dynamic>.from(raw as Map);
    final description =
        quest['description'] ?? quest['title'] ?? 'Misión';
    final target = quest['targetValue'] is num
        ? (quest['targetValue'] as num).toInt()
        : 1;
    final current = quest['currentValue'] is num
        ? (quest['currentValue'] as num).toInt()
        : 0;
    final done = quest['done'] == true || quest['isCompleted'] == true;
    final claimed = quest['claimed'] == true || quest['chestClaimed'] == true;
    final requiresCamera = quest['requiresCamera'] == true;
    final kind = quest['kind']?.toString() ?? 'daily';
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    Color barColor = AppColors.primary;
    if (kind == 'villain') barColor = Colors.deepOrangeAccent;
    if (kind == 'challenge') barColor = AppColors.secondary;
    if (done) barColor = Colors.green;

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
            description.toString(),
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
                  color: barColor,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              if (done && !claimed)
                ElevatedButton(
                  onPressed: () => _claim(quest),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Reclamar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              else if (kind == 'villain' && !done)
                TextButton(
                  onPressed: () async {
                    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
                    final villainId = quest['villainId']?.toString() ?? '';
                    if (id <= 0 || villainId.isEmpty) return;
                    Map<String, dynamic>? battle = quest['battle'] is Map
                        ? Map<String, dynamic>.from(quest['battle'] as Map)
                        : null;
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => VillainBattleScreen(
                          questId: id,
                          villainId: villainId,
                          villainName: quest['villainName']?.toString() ?? 'Villano',
                          portraitAsset: quest['portraitAsset']?.toString(),
                          fightClipAsset: quest['fightClipAsset']?.toString() ??
                              'assets/battle/fight_$villainId.mp4',
                          battle: battle,
                          coachNote: quest['coachNote']?.toString(),
                        ),
                      ),
                    );
                    if (ok == true) _loadQuests();
                  },
                  child: Text(
                    'Combate',
                    style: GoogleFonts.inter(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (requiresCamera && !done)
                TextButton(
                  onPressed: () async {
                    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
                    if (id <= 0) return;
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => ChallengeProofScreen(
                          questId: id,
                          title: quest['title']?.toString() ?? 'Evidencia',
                          coachNote: quest['coachNote']?.toString() ?? '',
                        ),
                      ),
                    );
                    if (ok == true) _loadQuests();
                  },
                  child: Text(
                    'Cámara',
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Text(
                  done ? 'Listo' : '$current / $target',
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
