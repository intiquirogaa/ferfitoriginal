import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quest_celebration.dart';
import 'challenge_proof_screen.dart';
import 'villain_battle_screen.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({Key? key}) : super(key: key);

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  bool _isLoading = true;
  List<dynamic> _quests = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final data = await ApiService.getTodayQuests();
    List<dynamic> quests = [];
    List<Map<String, dynamic>> notifs = [];
    if (data != null) {
      if (data['quests'] is List) quests = List.from(data['quests']);
      if (data['notifications'] is List) {
        notifs = (data['notifications'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } else {
      final fallback = await ApiService.getDailyQuests();
      if (fallback != null) quests = fallback;
    }

    if (notifs.isNotEmpty) {
      await NotificationService.instance.scheduleChallengeNotifications(notifs);
    } else {
      // Notificación inmediata de briefing matutino si hay misiones
      final open = quests.where((q) => q['done'] != true && q['isCompleted'] != true).toList();
      if (open.isNotEmpty) {
        final first = open.first;
        await NotificationService.instance.showNow(
          id: 6999,
          title: 'Plan del día — Feo',
          body: first['coachNote']?.toString() ??
              first['description']?.toString() ??
              'Revisá tus misiones y ejecutá con buena técnica.',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _quests = quests;
      _isLoading = false;
      if (quests.isEmpty) {
        _error = 'No hay misiones por ahora. Volvé más tarde o entrená para generar el día.';
      }
    });
  }

  Future<void> _claim(Map<String, dynamic> quest) async {
    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
    if (id <= 0) return;
    final res = await ApiService.claimQuest(id);
    if (!mounted) return;
    if (res != null && res['success'] != false && res['error'] == null) {
      final coins = (res['coins'] is num) ? (res['coins'] as num).toInt() : 0;
      QuestCelebration.show(context, coinsEarned: coins > 0 ? coins : (quest['rewardCoins'] ?? 10));
      final msg = res['message']?.toString();
      if (msg != null && msg.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.primary),
        );
      }
      await _loadQuests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['error']?.toString() ?? 'No se pudo reclamar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openProof(Map<String, dynamic> quest) async {
    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
    if (id <= 0) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChallengeProofScreen(
          questId: id,
          title: quest['title']?.toString() ?? 'Evidencia de ejecución',
          coachNote: quest['coachNote']?.toString() ?? '',
          exerciseHint: (quest['exerciseKeywords'] is List &&
                  (quest['exerciseKeywords'] as List).isNotEmpty)
              ? (quest['exerciseKeywords'] as List).take(3).join(', ')
              : null,
        ),
      ),
    );
    if (ok == true) await _loadQuests();
  }

  Future<void> _openBattle(Map<String, dynamic> quest) async {
    final id = (quest['id'] is num) ? (quest['id'] as num).toInt() : 0;
    final villainId = quest['villainId']?.toString() ?? '';
    if (id <= 0 || villainId.isEmpty) return;
    Map<String, dynamic>? battle = quest['battle'] is Map
        ? Map<String, dynamic>.from(quest['battle'] as Map)
        : null;
    if (battle == null) {
      final brief = await ApiService.getBattleBrief(villainId);
      if (brief != null && brief['battle'] is Map) {
        battle = Map<String, dynamic>.from(brief['battle'] as Map);
      }
    }
    if (!mounted) return;
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
    if (ok == true) await _loadQuests();
  }

  Color _kindColor(String? kind) {
    switch (kind) {
      case 'villain':
        return Colors.deepOrangeAccent;
      case 'challenge':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _kindLabel(String? kind) {
    switch (kind) {
      case 'villain':
        return 'VILLANO';
      case 'challenge':
        return 'DESAFÍO';
      default:
        return 'MISIÓN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Misiones del coach',
          style: GoogleFonts.rajdhani(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundDeep,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadQuests,
              child: _quests.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error ?? 'Sin misiones',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.mutedForeground),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Feo — tu entrenador personal',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Misiones diarias, desafíos con aviso y combates contra villanos. '
                          'Ejecutá con técnica; reclamá la recompensa al cerrar cada objetivo.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._quests.map((q) {
                          final quest = Map<String, dynamic>.from(q as Map);
                          return _buildCard(quest);
                        }),
                      ],
                    ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> quest) {
    final title = quest['title']?.toString() ?? 'Misión';
    final description = quest['description']?.toString() ?? '';
    final coachNote = quest['coachNote']?.toString() ?? '';
    final target = (quest['targetValue'] as num?)?.toInt() ??
        (quest['target'] as num?)?.toInt() ??
        1;
    final current = (quest['currentValue'] as num?)?.toInt() ??
        (quest['current'] as num?)?.toInt() ??
        0;
    final coins = (quest['rewardCoins'] as num?)?.toInt() ??
        (quest['coins'] as num?)?.toInt() ??
        0;
    final done = quest['done'] == true || quest['isCompleted'] == true;
    final claimed = quest['claimed'] == true || quest['chestClaimed'] == true;
    final requiresCamera = quest['requiresCamera'] == true;
    final kind = quest['kind']?.toString() ?? 'daily';
    final villainName = quest['villainName']?.toString();
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final accent = _kindColor(kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? accent.withOpacity(0.7) : AppColors.borderSolid,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _kindLabel(kind),
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '+$coins',
                style: GoogleFonts.inter(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.rajdhani(
              color: AppColors.foreground,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (villainName != null && villainName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Objetivo: $villainName',
              style: GoogleFonts.inter(
                color: Colors.deepOrangeAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(
                color: AppColors.mutedForeground,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          if (coachNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Coach: $coachNote',
                style: GoogleFonts.inter(
                  color: AppColors.foreground.withOpacity(0.9),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.background,
                    color: done ? Colors.greenAccent : accent,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$current / $target',
                style: GoogleFonts.inter(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (kind == 'villain' && !done)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openBattle(quest),
                    icon: const Icon(Icons.sports_mma, size: 18),
                    label: Text(
                      'Entrar al combate',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              if (kind == 'villain' && !done) const SizedBox(width: 8),
              if (requiresCamera && !done && kind != 'villain')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openProof(quest),
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    label: Text(
                      'Grabar evidencia',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ),
              if (requiresCamera && !done && kind != 'villain')
                const SizedBox(width: 8),
              if (done && !claimed)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _claim(quest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(
                      'Reclamar recompensa',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (done && claimed)
                Expanded(
                  child: Text(
                    'Recompensa reclamada',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
