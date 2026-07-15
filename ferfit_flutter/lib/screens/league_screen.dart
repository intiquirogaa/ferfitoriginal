import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({Key? key}) : super(key: key);

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  bool _isLoading = true;
  String _leagueName = 'Liga';
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadLeague();
  }

  Future<void> _loadLeague() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getLeagueLeaderboard();
    if (mounted) {
      setState(() {
        if (data != null) {
          _leagueName = data['leagueName'] ?? 'Liga Bronce';
          _users = data['users'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_leagueName, style: const TextStyle(color: AppColors.foreground)),
        backgroundColor: AppColors.backgroundDeep,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _users.isEmpty
              ? const Center(
                  child: Text(
                    'No hay jugadores en esta liga',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final name = user['name'] ?? 'Usuario';
                    final xp = (user['xp'] as num?)?.toInt() ?? 0;
                    
                    // We check for some identifier that indicates this is the current user.
                    // Depending on the backend this might be 'isCurrentUser', 'isMe', etc.
                    final isMe = user['isCurrentUser'] == true || user['isMe'] == true;
                    
                    final isTop3 = index < 3;
                    Color rankColor;
                    if (index == 0) rankColor = Colors.amber;
                    else if (index == 1) rankColor = Colors.grey[400]!;
                    else if (index == 2) rankColor = Colors.brown[300]!;
                    else rankColor = AppColors.mutedForeground;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary.withOpacity(0.1) : AppColors.cardSolid,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMe ? AppColors.primary : AppColors.borderSolid,
                          width: isMe ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.backgroundDeep,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: rankColor,
                              fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            color: isMe ? AppColors.primary : AppColors.foreground,
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '$xp XP',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
