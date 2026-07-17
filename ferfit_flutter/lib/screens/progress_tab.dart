import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../onboarding/coach_tour_keys.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/badges_grid.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _historyData;
  List<dynamic> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getDashboard();
    final history = await ApiService.getTrainingHistory();
    final badgesResp = await ApiService.getBadges();
    if (mounted) {
      setState(() {
        if (response != null && response['success'] == true) {
          _progress = response['progress'];
        }
        if (history != null && history['success'] == true) {
          _historyData = history;
        }
        if (badgesResp != null) {
          _badges = badgesResp;
        }
        _isLoading = false;
      });
    }
  }

  String _getLevelName(int level) {
    if (level < 5) return 'Novato';
    if (level < 15) return 'Intermedio';
    if (level < 30) return 'Avanzado';
    return 'Atleta de Élite';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final totalXP = _progress?['totalXP'] ?? 0;
    final level = _progress?['level'] ?? 1;
    final streak = _progress?['streak'] ?? 0;
    final seriesCompleted = _progress?['seriesCompletedHistorically'] ?? 0;
    
    final completedDates = _historyData?['completedDates'] as List<dynamic>? ?? [];
    final totalTrainedDates = completedDates.length;

    final currentLevelXP = totalXP % 500;
    final progressToNext = currentLevelXP / 500.0;
    final xpNeeded = 500 - currentLevelXP;

    return RefreshIndicator(
      onRefresh: _loadProgress,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: CoachTourKeys.progressHeader,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progreso',
                    style: GoogleFonts.rajdhani(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Historial, estadísticas y logros de\nentrenamiento',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nivel Actual Card
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIVEL ACTUAL', style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1.0)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$level', style: GoogleFonts.rajdhani(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(_getLevelName(level), style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$currentLevelXP / 500 XP', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400])),
                            Text('$xpNeeded XP para nivel ${level + 1}', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressToNext,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // XP Circle
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: progressToNext,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.trophy, color: AppColors.primary, size: 28),
                              const SizedBox(height: 4),
                              Text('LEVEL\nPROGRESS', textAlign: TextAlign.center, style: GoogleFonts.rajdhani(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[400], height: 1.1)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // STATS GRID
            Row(
              children: [
                Expanded(child: _buildStatCard(LucideIcons.zap, 'XP Total', '$totalXP', 'puntos')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(LucideIcons.flame, 'Racha Actual', '$streak', 'días')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard(LucideIcons.trendingUp, 'Series Completadas', '$seriesCompleted', 'series')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(LucideIcons.target, 'Total Entrenado', '$totalTrainedDates', 'días completados', isPurple: true)),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('LOGROS OBTENIDOS', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.0)),
            const SizedBox(height: 16),
            
            // Achievements Grid
            BadgesGrid(badges: _badges),

            const SizedBox(height: 24),
            Text('PROGRESO EN EJERCICIOS CLAVE', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.0)),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final exercises = _progress?['keyExercisesProgress'] as List<dynamic>? ?? [];
                if (exercises.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text('Completá más entrenamientos para ver tu progreso aquí.', style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13)),
                    ),
                  );
                }
                return Column(
                  children: exercises.map((ex) {
                    final dataList = ex['data'] as List<dynamic>? ?? [];
                    final chartData = dataList.map((e) => (e as num).toDouble()).toList();
                    final maxWeight = ex['maxWeight'] != null && ex['maxWeight'] > 0 ? '${ex['maxWeight']} kg' : null;
                    final maxReps = '${ex['maxReps'] ?? 0}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildChartCard(ex['name'] ?? 'Ejercicio', chartData, maxWeight, maxReps, '-', '-'),
                    );
                  }).toList(),
                );
              }
            ),
            
            const SizedBox(height: 24),
            Text('HISTORIAL DE CALENDARIO', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.0)),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_getMonthName(DateTime.now().month)} De ${DateTime.now().year}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Row(
                        children: [
                          Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Hoy', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildRealCalendar(completedDates),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, String sub, {bool isPurple = false}) {
    final color = isPurple ? Colors.purpleAccent : AppColors.primary;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(sub, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }


  Widget _buildChartCard(String title, List<double> chartData, String? maxWeight, String maxReps, String time, String xp) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (maxWeight != null) ...[
                Expanded(child: _buildMiniStat(LucideIcons.weight, 'Peso Máximo', maxWeight, 'Promedio')),
                const SizedBox(width: 12),
              ],
              Expanded(child: _buildMiniStat(LucideIcons.trendingUp, 'Máx. Reps', maxReps, 'Repeticiones')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniStat(LucideIcons.clock, 'Tiempo Total', time, 'Acumulado')),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStat(LucideIcons.zap, 'XP Ganado', xp, 'Total', valueColor: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1, dashArray: [5, 5]),
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1, dashArray: [5, 5]),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: TextStyle(color: Colors.grey[500], fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text('Jun ${20 + (val.toInt()*2)}', style: TextStyle(color: Colors.grey[500], fontSize: 10)))),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: chartData.length > 1 ? (chartData.length - 1).toDouble() : 1,
                minY: 0,
                maxY: chartData.isEmpty ? 100 : chartData.reduce((a, b) => a > b ? a : b) * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.5), AppColors.primary.withOpacity(0.0)],
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

  Widget _buildMiniStat(IconData icon, String title, String value, String sub, {Color valueColor = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[500], size: 14),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600])),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    return months[month - 1];
  }

  Widget _buildRealCalendar(List<dynamic> completedDates) {
    final days = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    // Day of week of the 1st (0 = Monday, 6 = Sunday in Dart, but we want 0 = Sunday)
    int startOffset = firstDayOfMonth.weekday % 7; 
    
    Set<int> trainedDays = {};
    for (var dateStr in completedDates) {
      if (dateStr == null) continue;
      try {
        final d = DateTime.parse(dateStr.toString());
        if (d.year == now.year && d.month == now.month) {
          trainedDays.add(d.day);
        }
      } catch (_) {}
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => Text(d, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]))).toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: lastDayOfMonth.day + startOffset,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox();
            final day = index - startOffset + 1;
            final isTraining = trainedDays.contains(day);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isTraining ? Border.all(color: Colors.purpleAccent.withOpacity(0.5), width: 2) : null,
                color: isTraining ? Colors.purpleAccent.withOpacity(0.1) : Colors.transparent,
              ),
              child: Center(
                child: Text('$day', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isTraining ? Colors.white : Colors.grey[700])),
              ),
            );
          },
        ),
      ],
    );
  }
}
