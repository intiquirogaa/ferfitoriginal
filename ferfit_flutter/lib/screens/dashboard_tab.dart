import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../services/engagement_service.dart';
import '../widgets/plan_wizard.dart';
import '../widgets/glass_card.dart';
import '../widgets/engagement_banner.dart';
import '../widgets/xp_counter_animated.dart';
import '../widgets/streak_flame_widget.dart';
import '../widgets/feo_notification_overlay.dart';
import '../widgets/feo_streak_freeze_dialog.dart';
import '../widgets/daily_quests_widget.dart';
import 'feo_chat_screen.dart';
import 'feo_store_screen.dart';
import 'quests_screen.dart';
import 'league_screen.dart';
import 'social_screen.dart';
class DashboardTab extends StatefulWidget {
  final VoidCallback? onOpenWorkout;

  const DashboardTab({super.key, this.onOpenWorkout});

  @override
  State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
  Map<String, dynamic>? _dashData;
  Map<String, dynamic>? _progress;
  List<dynamic>? _tips;
  Map<String, dynamic>? _checklist;
  Map<String, dynamic>? _engagementAlert;
  bool _isLoading = true;
  String _userName = 'Inti';
  bool _hasActivePlan = false;
  int _currentTipIndex = 0;
  String? _motivationalQuote;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> reloadEngagement() async {
    final alert = await EngagementService.instance.primaryAlert();
    if (mounted) setState(() => _engagementAlert = alert);
  }

  int _asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _asDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name') ?? 'Inti';

      // Cargas en paralelo; fallos individuales no tiran todo el dashboard
      final results = await Future.wait([
        ApiService.getDashboard().catchError((_) => null),
        ApiService.getTips().catchError((_) => null),
        ApiService.getTodayChecklist().catchError((_) => null),
        ApiService.getActivePlan().catchError((_) => null),
        ApiService.getMotivationalQuote().catchError((_) => null),
      ]);

      final dash = results[0] as Map<String, dynamic>?;
      final tips = results[1] as List<dynamic>?;
      final checklist = results[2] as Map<String, dynamic>?;
      final plan = results[3] as Map<String, dynamic>?;
      final quote = results[4] as String?;

      Map<String, dynamic>? alert;
      try {
        await EngagementService.instance.onAppOpened(userName: savedName);
        alert = await EngagementService.instance.primaryAlert();
      } catch (e) {
        print('Engagement load error: $e');
      }

      if (!mounted) return;
      setState(() {
        _userName = savedName;
        final planObj = plan?['plan'];
        _hasActivePlan = plan != null &&
            plan['success'] == true &&
            planObj is Map &&
            (planObj['hasPlan'] == true || planObj['id'] != null || planObj['generatedContent'] != null);
        if (dash != null) {
          final d = dash['dashboard'];
          _dashData = d is Map<String, dynamic> ? d : (d is Map ? Map<String, dynamic>.from(d) : null);
          final p = dash['progress'];
          _progress = p is Map<String, dynamic> ? p : (p is Map ? Map<String, dynamic>.from(p) : null);
        }
        _tips = tips;
        final cl = checklist?['checklist'];
        _checklist = cl is Map<String, dynamic> ? cl : (cl is Map ? Map<String, dynamic>.from(cl) : null);
        _engagementAlert = alert;
        _motivationalQuote = quote;
        _isLoading = false;
      });

      if (alert != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final alertData = alert!;
          final type = alertData['type']?.toString();
          if (type == 'streak_at_risk') {
            FeoStreakFreezeDialog.show(
              context,
              streak: _asInt(alertData['streak']),
              daysLeft: 1,
              onSave: () {
                Navigator.of(context).pop();
                _handleEngagementCta();
              },
            );
          } else {
            FeoNotificationOverlay.show(
              context,
              title: alertData['title']?.toString() ?? 'Atención',
              body: alertData['body']?.toString() ?? '',
              type: type,
              cta: alertData['cta']?.toString(),
              onCta: _handleEngagementCta,
              onDismiss: _dismissEngagement,
            );
          }
        });
      }
    } catch (e) {
      print('Dashboard _loadData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dismissEngagement() async {
    final id = _engagementAlert?['id']?.toString();
    if (id != null) {
      await EngagementService.instance.dismiss(id);
    }
    if (mounted) setState(() => _engagementAlert = null);
  }

  void _handleEngagementCta() {
    final action = _engagementAlert?['action']?.toString() ?? 'open_workout';
    if (action == 'create_plan') {
      _showCreatePlanWizard();
      return;
    }
    if (action == 'open_workout') {
      widget.onOpenWorkout?.call();
      return;
    }
    // open_dashboard: ya estamos
  }

  void _showCreatePlanWizard() {
    PlanWizardDialog.show(
      context,
      onPlanCreated: _loadData,
    );
  }

  void _loadDemoPlan() async {
    setState(() => _isLoading = true);
    final result = await ApiService.createPlan({
      'gender': 'male', 'age': 30, 'weight': 80.0, 'height': 175.0,
      'objective': 'strength', 'experienceLevel': 'beginner',
      'equipment': 'full_gym', 'injuries': '', 'preferences': 'Upper/Lower split',
      'daysPerWeek': 3, 'useDemo': true, 
    });
    if (result == null || result['success'] != true) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar plan.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    _loadData();
  }

  String _getDateString() {
    final now = DateTime.now();
    final weekdays = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    final months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${weekdays[now.weekday % 7]}, ${now.day} de ${months[now.month - 1]}';
  }

  Widget _buildWeeklyProgressChart() {
    final weeklyProgress = _dashData?['weeklyProgress'] as List<dynamic>? ?? [];
    List<FlSpot> seriesSpots = [];
    List<FlSpot> xpSpots = [];
    if (weeklyProgress.isEmpty) {
      seriesSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
      xpSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
    } else {
      for (int i = 0; i < weeklyProgress.length; i++) {
        final dayData = weeklyProgress[i];
        seriesSpots.add(FlSpot(i.toDouble(), _asDouble(dayData['series'])));
        xpSpots.add(FlSpot(i.toDouble(), _asDouble(dayData['xp'])));
      }
    }

    double maxY = xpSpots.isEmpty ? 100 : xpSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxY < 10) maxY = 10;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY PROGRESS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Historial de Series y XP',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem(AppColors.primary, 'Series'),
                  const SizedBox(width: 12),
                  _buildLegendItem(AppColors.secondary, 'XP Ganado'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                        if (value >= 0 && value < days.length) {
                          return Text(days[value.toInt()], style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY > 50 ? maxY / 2 : 10,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(value.toInt().toString(), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600));
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6,
                minY: 0, maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: xpSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: seriesSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.5),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 4, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildWorkoutChecklist() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY WORKOUT CHECKLIST',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus metas de entrenamiento para hoy',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text('Hoy', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_hasActivePlan)
             Center(
               child: ElevatedButton(
                 onPressed: _showCreatePlanWizard,
                 style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                 child: const Text('Crear Plan de Entrenamiento'),
               ),
             )
          else
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.backgroundDeep.withOpacity(0.4),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 children: [
                   Container(
                     width: 40, height: 40,
                     decoration: BoxDecoration(
                       color: AppColors.primary.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(10),
                       border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                     ),
                     child: const Icon(LucideIcons.dumbbell, color: AppColors.primary, size: 20),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Rutina del Día', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                         const SizedBox(height: 4),
                         Builder(builder: (_) {
                           final total = _asInt(_checklist?['totalSeries']);
                           final done = _asInt(_checklist?['completedSeries']);
                           final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
                           return LinearProgressIndicator(
                             value: ratio,
                             backgroundColor: Colors.grey[800],
                             color: AppColors.primary,
                             minHeight: 4,
                             borderRadius: BorderRadius.circular(2),
                           );
                         }),
                       ],
                     ),
                   ),
                 ],
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    final level = _asInt(_progress?['level'], 1);
    final totalXP = _asInt(_progress?['totalXP']);
    
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: XpCounterAnimated(
          currentXP: totalXP,
          level: level,
          xpForNextLevel: 500,
          showLevel: true,
          compact: false,
        ),
      ),
    );
  }

  Widget _buildMetricDualCard() {
    final stats = _dashData?['fitnessStats'] ?? {};
    final totalSeries = _asInt(stats['weeklyTotalSeries']);
    final totalXP = _asInt(stats['weeklyTotalXP']);

    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL SERIES', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalSeries', style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('esta semana', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP SEMANAL', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$totalXP', style: GoogleFonts.rajdhani(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('esta semana', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 4, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFitnessStatsOverview() {
    final stats = _dashData?['fitnessStats'] ?? {};
    final streak = _asInt(stats['streak']);
    final totalWorkouts = _asInt(stats['totalWorkouts']);
    final level = _asInt(stats['level'], 1);

    // Determines if streak is at risk (e.g. no plan completed today)
    final isAtRisk = _engagementAlert?['type'] == 'streak_at_risk';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FITNESS STATS OVERVIEW', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[300], letterSpacing: 1.0)),
              StreakFlameWidget(
                streak: streak,
                isAtRisk: isAtRisk,
                size: 50,
                showCount: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Días Entrenados', '$totalWorkouts', 'Total Histórico', AppColors.primary, [0, totalWorkouts.toDouble()]),
          const SizedBox(height: 20),
          _buildStatRow('Nivel de Atleta', 'Lvl $level', 'Progreso', AppColors.primary, [0, level.toDouble()]),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String subValue, Color color, List<double> spots) {
    double maxY = spots.isEmpty ? 10 : spots.reduce((a, b) => a > b ? a : b) * 1.5;
    if (maxY == 0) maxY = 10;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 6),
                Text(subValue, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        SizedBox(
          width: 80, height: 30,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: spots.length > 1 ? spots.length.toDouble() - 1 : 1,
              minY: 0, maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCarousel() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.yellow[700]!.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(LucideIcons.lightbulb, color: Colors.yellow[700], size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Consejos para vos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_tips != null && _tips!.isNotEmpty) {
                        setState(() { _currentTipIndex = (_currentTipIndex - 1) % _tips!.length; if (_currentTipIndex < 0) _currentTipIndex = _tips!.length - 1; });
                      }
                    },
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                      child: const Icon(Icons.chevron_left, color: Colors.grey, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_tips != null && _tips!.isNotEmpty) {
                        setState(() { _currentTipIndex = (_currentTipIndex + 1) % _tips!.length; });
                      }
                    },
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                      child: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDeep.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                      child: const Icon(LucideIcons.droplets, color: AppColors.primary, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Hidratate', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Recordá tomar al menos 2L de agua al día.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 16, height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 4),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.zap, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('Generado por IA según tu actividad', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationHub(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHubButton(context, icon: LucideIcons.store, label: 'Tienda', color: Color(0xFFFBBF24), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeoStoreScreen()))),
          _buildHubButton(context, icon: LucideIcons.target, label: 'Misiones', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsScreen()))),
          _buildHubButton(context, icon: LucideIcons.trophy, label: 'Ligas', color: AppColors.secondary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeagueScreen()))),
          _buildHubButton(context, icon: LucideIcons.users, label: 'Amigos', color: Color(0xFFF472B6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialScreen()))),
        ],
      ),
    );
  }

  Widget _buildHubButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Hola, ',
                    style: GoogleFonts.rajdhani(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: _userName,
                    style: GoogleFonts.rajdhani(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(text: ' 👋', style: TextStyle(fontSize: 28)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getDateString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            // --- Feo Chat Card ---
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeoChat())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF39C34B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF39C34B), Color(0xFF2EA043)]),
                      ),
                      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hablar con Feo', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            _motivationalQuote ?? '¡Tu entrenador personal está listo! 🔥',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF39C34B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            _buildGamificationHub(context),
            const SizedBox(height: 24),

            _buildWeeklyProgressChart(),
            const SizedBox(height: 16),
            
            _buildWorkoutChecklist(),
            const SizedBox(height: 16),

            _buildLevelProgress(),
            const SizedBox(height: 16),

            _buildMetricDualCard(),
            const SizedBox(height: 16),

            _buildFitnessStatsOverview(),
            const SizedBox(height: 16),

            const DailyQuestsWidget(),
            const SizedBox(height: 16),

            _buildTipsCarousel(),
            const SizedBox(height: 20),

            // --- DEBUG NOTIFICATIONS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Herramientas de Prueba (Debug)', style: GoogleFonts.rajdhani(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      FeoNotificationOverlay.show(
                        context,
                        title: '¡No pierdas tu racha!',
                        body: 'Feo nota que no has entrenado hoy.',
                        type: 'streak_at_risk',
                      );
                    },
                    child: const Text('Probar Notificación Flotante'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      FeoStreakFreezeDialog.show(
                        context,
                        streak: 5,
                        daysLeft: 1,
                        onSave: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Racha salvada!')));
                        }
                      );
                    },
                    child: const Text('Probar Diálogo Salvar Racha'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
