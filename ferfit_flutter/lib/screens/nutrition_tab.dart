import 'dart:convert';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../widgets/nutrition_wizard.dart';
import '../widgets/glass_card.dart';
import '../widgets/ai_nutrition_widgets.dart';

class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  Map<String, dynamic>? _nutritionPlan;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadNutrition();
  }

  double _asDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(s) ?? fallback;
  }

  Future<void> _loadNutrition() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      Map<String, dynamic>? plan;

      // 1) Plan nutricional dedicado (tabla nutrition_plans)
      final nutritionRes = await ApiService.getActiveNutritionPlan();
      if (nutritionRes != null &&
          nutritionRes['success'] == true &&
          nutritionRes['hasPlan'] == true &&
          nutritionRes['plan'] is Map) {
        plan = Map<String, dynamic>.from(nutritionRes['plan'] as Map);
      }

      // 2) Fallback: nutrition dentro del plan de entrenamiento
      plan ??= await _nutritionFromTrainingPlan();

      if (!mounted) return;
      setState(() {
        _nutritionPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      print('Nutrition load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _nutritionFromTrainingPlan() async {
    try {
      final response = await ApiService.getActivePlan();
      if (response == null || response['success'] != true) return null;
      final plan = response['plan'];
      if (plan is! Map) return null;
      dynamic generatedContent = plan['generatedContent'];
      if (generatedContent is String) {
        try {
          generatedContent = jsonDecode(generatedContent);
        } catch (_) {
          return null;
        }
      }
      if (generatedContent is Map && generatedContent['nutrition'] is Map) {
        return Map<String, dynamic>.from(generatedContent['nutrition'] as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showCreatePlanWizard() {
    NutritionWizardDialog.show(
      context,
      onPlanCreated: _loadNutrition,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final dietData = _nutritionPlan;
    final hasPlan = dietData != null &&
        (dietData['meals'] is List) &&
        (dietData['meals'] as List).isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadNutrition,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nutrition',
              style: GoogleFonts.rajdhani(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tu plan de alimentación diario',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              Text(_loadError!, style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
            ],
            const SizedBox(height: 24),
            // --- Herramientas de IA ---
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => SmartLogBottomSheet.show(context, onLogged: _loadNutrition),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF39C34B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF39C34B), size: 18),
                          const SizedBox(width: 8),
                          Text('Cargar comida IA', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FridgeRecipeBottomSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.kitchen, color: Color(0xFFFFB347), size: 18),
                          const SizedBox(width: 8),
                          Text('Receta Heladera', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!hasPlan)
              _buildEmptyState()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TODAY'S MEAL PLAN",
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton(
                    onPressed: _showCreatePlanWizard,
                    child: Text('Nuevo', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildMealsList(dietData),
              const SizedBox(height: 32),
              Text(
                'MACRONUTRIENTS',
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              _buildMacronutrientsChart(dietData),
              const SizedBox(height: 24),
              if (dietData['hydration'] != null)
                _buildInfoCard(
                  icon: LucideIcons.droplet,
                  title: 'Hidratación',
                  description: dietData['hydration'].toString(),
                ),
              if (dietData['supplementation'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: LucideIcons.pill,
                  title: 'Suplementación',
                  description: dietData['supplementation'].toString(),
                ),
              ],
              if (dietData['notes'] != null) ...[
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: LucideIcons.fileText,
                  title: 'Notas',
                  description: dietData['notes'].toString(),
                ),
              ],
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Icon(LucideIcons.apple, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin plan nutricional',
            style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Creá tu plan de alimentación personalizado (calorías, macros y comidas).',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreatePlanWizard,
            icon: const Icon(LucideIcons.plus, size: 16, color: Colors.black),
            label: Text(
              'Crear plan de alimentación',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealsList(Map<String, dynamic> diet) {
    final mealsList = diet['meals'] as List<dynamic>? ?? [];
    if (mealsList.isEmpty) return [];

    return mealsList.map<Widget>((raw) {
      final mealData = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final name = (mealData['name'] ?? 'Comida').toString().toUpperCase();
      final macros = mealData['macros'] is Map
          ? Map<String, dynamic>.from(mealData['macros'] as Map)
          : <String, dynamic>{};
      final calories = _asDouble(mealData['calories']).round();
      final protein = _asDouble(macros['protein']).round();
      final carbs = _asDouble(macros['carbs']).round();
      final fats = _asDouble(macros['fats']).round();

      final foodsList = mealData['foods'] as List<dynamic>? ?? [];
      final ingredients = foodsList.take(4).map((e) {
        if (e is Map) {
          final n = e['name']?.toString() ?? 'Alimento';
          final q = e['quantity'];
          final u = e['unit']?.toString() ?? '';
          if (q != null) return '$n $q$u'.trim();
          return n;
        }
        return e.toString();
      }).toList();
      if (ingredients.isEmpty) ingredients.add('Alimentos del plan');

      final timeStr = mealData['time']?.toString() ?? '';

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.cardGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$calories kcal',
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .map(
                      (ing) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          ing,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroInfo('PROT', '${protein}g', const Color(0xFFC084FC)),
                  _buildMacroInfo('CARBS', '${carbs}g', AppColors.primary),
                  _buildMacroInfo('GRASAS', '${fats}g', AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        if (value.isNotEmpty)
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMacronutrientsChart(Map<String, dynamic> diet) {
    final dailyCalories = _asDouble(diet['dailyCalories'], 2000).round();
    final dailyMacros = diet['dailyMacros'] is Map
        ? Map<String, dynamic>.from(diet['dailyMacros'] as Map)
        : <String, dynamic>{};

    var prot = _asDouble(dailyMacros['protein'], 30);
    var carbs = _asDouble(dailyMacros['carbs'], 50);
    var fats = _asDouble(dailyMacros['fats'], 20);
    if (prot + carbs + fats <= 0) {
      prot = 30;
      carbs = 50;
      fats = 20;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(color: const Color(0xFFC084FC), value: prot, title: '', radius: 12),
                      PieChartSectionData(color: AppColors.primary, value: carbs, title: '', radius: 12),
                      PieChartSectionData(color: Colors.green[800], value: fats, title: '', radius: 12),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dailyCalories kcal',
                        style: GoogleFonts.rajdhani(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calorías diarias',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMacroInfo('PROT ${prot.round()}g', '', const Color(0xFFC084FC)),
              _buildMacroInfo('CARBS ${carbs.round()}g', '', AppColors.primary),
              _buildMacroInfo('GRASAS ${fats.round()}g', '', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
