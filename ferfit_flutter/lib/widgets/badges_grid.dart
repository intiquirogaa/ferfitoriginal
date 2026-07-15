import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class BadgesGrid extends StatelessWidget {
  final List<dynamic> badges;

  const BadgesGrid({super.key, required this.badges});

  IconData _getIconForBadge(String iconName) {
    switch (iconName) {
      case 'zap': return LucideIcons.zap;
      case 'flame': return LucideIcons.flame;
      case 'dumbbell': return LucideIcons.dumbbell;
      case 'trophy': return LucideIcons.trophy;
      default: return LucideIcons.award;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Text(
          'Todavía no hay medallas disponibles.',
          style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final bool unlocked = badge['unlocked'] == true;
        final name = badge['name'] ?? '';
        final description = badge['description'] ?? '';
        final iconStr = badge['icon'] ?? 'award';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: unlocked ? AppColors.cardGlass : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: unlocked ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unlocked ? AppColors.primary.withOpacity(0.2) : Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForBadge(iconStr),
                  color: unlocked ? AppColors.primary : Colors.grey[500],
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? Colors.white : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  unlocked ? description : 'Bloqueado',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: unlocked ? Colors.grey[400] : Colors.grey[700],
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
