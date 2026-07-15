import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/feo_exercise_catalog.dart';
import '../widgets/plan_wizard.dart';
import '../widgets/glass_card.dart';
import '../widgets/feo_celebration.dart';
import '../widgets/feo_exercise_demo.dart';
import '../widgets/ferfit_mascot.dart';
import '../widgets/feo_loading_indicator.dart';
import '../widgets/daily_goal_ring.dart';

class WorkoutTab extends StatefulWidget {
  const WorkoutTab({super.key});

  @override
  State<WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<WorkoutTab> {
  Map<String, dynamic>? _planData;
  Map<String, dynamic>? _generatedContent;
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  final Set<String> _expandedExercises = {};
  final Map<String, String> _exerciseMediaUrls = {};

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getActivePlan();
    if (mounted) {
      setState(() {
        if (response != null && response['success'] == true) {
          _planData = response['plan'];
          if (_planData != null && _planData!['generatedContent'] != null) {
            final generatedContent = _planData!['generatedContent'];
            if (generatedContent is String) {
              try {
                _generatedContent = jsonDecode(generatedContent) as Map<String, dynamic>?;
              } catch (_) {
                _generatedContent = null;
              }
            } else if (generatedContent is Map<String, dynamic>) {
              _generatedContent = generatedContent;
            } else {
              _generatedContent = null;
            }

            if (_generatedContent != null) {
              final days = _generatedContent!['days'] as List<dynamic>?;
              if (days != null && days.isNotEmpty) {
                int firstIncomplete = 0;
                for (int i = 0; i < days.length; i++) {
                  final exercises = (days[i]['exercises'] as List<dynamic>?) ?? [];
                  if (!_isDayComplete(exercises)) {
                    firstIncomplete = i;
                    break;
                  }
                }
                _selectedDayIndex = firstIncomplete;
              }
            }
          } else {
            _generatedContent = null;
          }
        } else {
          _planData = null;
          _generatedContent = null;
        }
        _isLoading = false;
      });
    }
  }

  /// ¿Todas las series de un ejercicio están marcadas?
  bool _isExerciseComplete(Map<String, dynamic> ex) {
    final sets = (ex['sets'] as num?)?.toInt() ?? 3;
    final seriesMap = ex['seriesCompleted'] as Map<String, dynamic>? ?? {};
    for (var i = 0; i < sets; i++) {
      if (seriesMap[i.toString()] != true) return false;
    }
    return sets > 0;
  }

  /// ¿Todo el día está completo?
  bool _isDayComplete(List<dynamic> exercises) {
    if (exercises.isEmpty) return false;
    for (final raw in exercises) {
      if (raw is! Map) return false;
      if (!_isExerciseComplete(Map<String, dynamic>.from(raw))) return false;
    }
    return true;
  }

  Future<void> _toggleSetCompletion(int dayIndex, int exIndex, int setIndex, bool currentVal) async {
    if (currentVal) return; // Una vez completada, no se puede deshacer
    
    final trainingDays = _generatedContent?['days'] as List<dynamic>?;
    if (trainingDays == null || _planData == null) return;

    final planId = _planData!['id'] as int;
    final newValue = !currentVal;

    // Update local state immediately for fast UI feedback
    setState(() {
      final ex = trainingDays[dayIndex]['exercises'][exIndex];
      if (ex['seriesCompleted'] == null) {
        ex['seriesCompleted'] = <String, dynamic>{};
      }
      ex['seriesCompleted'][setIndex.toString()] = newValue;
    });

    // Call API (no bloqueamos la celebración si falla la red)
    // ignore: unawaited_futures
    ApiService.completeSeries(
      trainingPlanId: planId,
      dayNumber: dayIndex + 1,
      exerciseIndex: exIndex,
      seriesIndex: setIndex,
      completed: newValue,
    );

    // Feo celebra solo al completar (no al desmarcar)
    if (!newValue || !mounted) return;

    final day = trainingDays[dayIndex];
    final exercises = (day['exercises'] as List<dynamic>?) ?? [];
    final ex = Map<String, dynamic>.from(exercises[exIndex] as Map);
    final exerciseName =
        (ex['nameEs'] ?? ex['name'] ?? ex['exerciseName'] ?? 'ejercicio').toString();

    if (_isDayComplete(exercises)) {
      await FeoCelebration.show(
        context,
        level: FeoCelebrationLevel.day,
      );
      return;
    }

    if (_isExerciseComplete(ex)) {
      await FeoCelebration.show(
        context,
        level: FeoCelebrationLevel.exercise,
        exerciseName: exerciseName,
      );
      return;
    }

    // Serie suelta: celebración corta de Feo
    await FeoCelebration.show(
      context,
      level: FeoCelebrationLevel.series,
      xpHint: 10,
    );
  }

  /// Extrae URL usable del plan o de la API mobile (string absoluta).
  String? _usableRemoteUrl(dynamic raw) {
    if (raw is! String) return null;
    final u = raw.trim();
    if (u.isEmpty) return null;
    if (u.startsWith('/exercises/')) return null; // paths rotos locales
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return null;
  }

  String _mediaKeyFor(Map<String, dynamic> ex) {
    return (ex['nameEn'] ?? ex['name'] ?? ex['nameEs'] ?? 'exercise').toString();
  }

  Future<void> _ensureExerciseMedia(Map<String, dynamic> ex) async {
    final key = _mediaKeyFor(ex);
    if (key.isEmpty) return;

    // 1) gifUrl ya en el plan (si es http/https)
    final fromPlan = _usableRemoteUrl(ex['gifUrl']);
    if (fromPlan != null) {
      if (_exerciseMediaUrls[key] != fromPlan) {
        setState(() => _exerciseMediaUrls[key] = fromPlan);
      }
      return;
    }
    if (_exerciseMediaUrls.containsKey(key)) return;

    // 2) API /exercise-media (busca con EN preferido)
    final searchName = (ex['nameEn'] ?? ex['name'] ?? key).toString();
    final media = await ApiService.getExerciseMedia(searchName);
    if (!mounted) return;
    final url = _usableRemoteUrl(media?['url']);
    if (url != null) {
      setState(() => _exerciseMediaUrls[key] = url);
    } else {
      // Marca vacío para no spinear infinito
      setState(() => _exerciseMediaUrls[key] = '');
    }
  }

  void _toggleExpanded(String name, [Map<String, dynamic>? ex]) async {
    setState(() {
      if (_expandedExercises.contains(name)) {
        _expandedExercises.remove(name);
      } else {
        _expandedExercises.add(name);
      }
    });

    if (_expandedExercises.contains(name) && ex != null) {
      await _ensureExerciseMedia(ex);
    }
  }

  void _showCreatePlanWizard() {
    PlanWizardDialog.show(
      context,
      onPlanCreated: _loadPlan,
    );
  }

  Future<void> _showAutoregulateDialog() async {
    if (_planData == null || _planData!['id'] == null) return;
    
    final planId = _planData!['id'] as int;
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardSolid,
          title: Text('Auto-regular Rutina', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '¿Cómo te sentís hoy?',
              hintStyle: TextStyle(color: Colors.grey[500]),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                
                final result = await ApiService.autoregulateWorkout(planId, _selectedDayIndex, textController.text);
                
                if (result != null && result['success'] == true && result['day'] != null) {
                  setState(() {
                    if (_generatedContent != null) {
                      final days = _generatedContent!['days'] as List<dynamic>;
                      days[_selectedDayIndex] = result['day'];
                    }
                  });
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al auto-regular la rutina.')),
                    );
                  }
                }
                
                setState(() => _isLoading = false);
              },
              child: const Text('Regular'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: FeoLoadingIndicator(size: 90));
    }

    final hasPlan = _generatedContent != null;
    final trainingDays = hasPlan ? (_generatedContent!['days'] as List<dynamic>?) : null;

    return RefreshIndicator(
      onRefresh: _loadPlan,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrenamiento',
                        style: GoogleFonts.rajdhani(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tu plan de entrenamiento personalizado',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPlan && trainingDays != null && trainingDays.isNotEmpty)
                  Builder(builder: (_) {
                    final dayData = trainingDays[_selectedDayIndex];
                    final exercises = (dayData['exercises'] as List<dynamic>?) ?? [];
                    int completedCount = 0;
                    for (final ex in exercises) {
                      if (_isExerciseComplete(Map<String, dynamic>.from(ex as Map))) completedCount++;
                    }
                    double progress = exercises.isEmpty ? 0.0 : completedCount / exercises.length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: DailyGoalRing(
                        progress: progress,
                        size: 60,
                        strokeWidth: 6,
                        exerciseCount: exercises.length,
                        completedExercises: completedCount,
                        showCenter: true,
                        animate: true,
                      ),
                    );
                  }),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreatePlanWizard,
                    icon: const Icon(LucideIcons.plus, size: 16, color: Colors.black),
                    label: Text(hasPlan ? 'Nuevo plan' : 'Crear plan', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (hasPlan)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showAutoregulateDialog,
                      icon: const Icon(LucideIcons.zap, size: 16, color: AppColors.primary),
                      label: Text('Auto-regular', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (!hasPlan)
              _buildEmptyState()
            else ...[
              // Day Controller
              _buildDayControllerCard(trainingDays),
              const SizedBox(height: 24),

              Text('TRAINING SESSIONS', style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(
                'ENFOQUE: ${(trainingDays![_selectedDayIndex]['focus'] ?? '').toString().toUpperCase()}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),

              // Exercises List
              ..._buildExercisesList(trainingDays[_selectedDayIndex]['exercises'] ?? []),
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
          const FerFitMascot(
            size: 100,
            mood: FerFitMascotMood.idle,
            anim: FeoAnim.wave,
            showName: true,
          ),
          const SizedBox(height: 20),
          Text('Feo espera tu plan', style: GoogleFonts.rajdhani(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            'Creá tu plan de entrenamiento personalizado con IA. Feo te va a acompañar serie a serie.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildDayControllerCard(List<dynamic>? days) {
    if (days == null || days.isEmpty) return const SizedBox.shrink();
    final dayData = days[_selectedDayIndex];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.backgroundDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[800]!)),
                child: const Icon(LucideIcons.calendar, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Día ${_selectedDayIndex + 1}: ${dayData['focus'] ?? 'Entrenamiento'}',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text('Mantén intensidad.', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = (_selectedDayIndex - 1) % days.length;
                    if (_selectedDayIndex < 0) _selectedDayIndex = days.length - 1;
                  });
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                  child: const Icon(Icons.chevron_left, color: Colors.grey, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_selectedDayIndex + 1}/${days.length}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDayIndex = (_selectedDayIndex + 1) % days.length;
                  });
                },
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                  child: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExercisesList(List<dynamic> exercises) {
    return exercises.asMap().entries.map((entry) {
      final idx = entry.key;
      final rawEx = entry.value;
      final ex = rawEx is Map<String, dynamic>
          ? rawEx
          : Map<String, dynamic>.from(rawEx as Map);
      final name = (ex['name'] ?? ex['nameEs'] ?? ex['nameEn'] ?? 'Ejercicio').toString();
      final mediaKey = _mediaKeyFor(ex);

      // Parse sets and reps since they might be int or string
      int sets = 3;
      if (ex['sets'] != null) {
        if (ex['sets'] is int) {
          sets = ex['sets'] as int;
        } else if (ex['sets'] is String) {
          sets = int.tryParse(ex['sets'] as String) ?? 3;
        } else if (ex['sets'] is num) {
          sets = (ex['sets'] as num).toInt();
        }
      }
      if (sets < 3) sets = 3;
      final reps = ex['reps']?.toString() ?? '10';

      final isExpanded = _expandedExercises.contains(name);
      final feoDemo = resolveFeoExerciseDemo(
        name: ex['name']?.toString(),
        nameEn: ex['nameEn']?.toString(),
        nameEs: ex['nameEs']?.toString(),
      );

      return GestureDetector(
        onTap: () => _toggleExpanded(name, ex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cardGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isExpanded ? AppColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isExpanded ? AppColors.primary : Colors.grey[900],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExpanded ? Colors.black : Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('$sets Sets × $reps Reps', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
                          if (feoDemo != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Feo te muestra cómo · ${feoDemo.titleEs}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary.withOpacity(0.9)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      ...List.generate(sets, (setIdx) {
                        final seriesMap = ex['seriesCompleted'] as Map<String, dynamic>? ?? {};
                        final isCompleted = seriesMap[setIdx.toString()] == true;

                        return GestureDetector(
                          onTap: isCompleted ? null : () => _toggleSetCompletion(_selectedDayIndex, idx, setIdx, isCompleted),
                          child: Opacity(
                            opacity: isCompleted ? 0.4 : 1.0,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isCompleted ? AppColors.primary.withOpacity(0.5) : Colors.transparent),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: isCompleted ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isCompleted ? AppColors.primary : Colors.grey[700]!),
                                    ),
                                    child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                                  ),
                                const SizedBox(width: 16),
                                Text('Set\n${setIdx + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, height: 1.1)),
                                const Spacer(),
                                Text('REPS', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                                const SizedBox(width: 8),
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                                  child: Text(isCompleted ? reps.toString() : '-', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                                const SizedBox(width: 16),
                                Text('LBS', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                                const SizedBox(width: 8),
                                Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                                  child: Text(isCompleted ? '0' : '-', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                      const SizedBox(height: 16),
                      Text(
                        feoDemo != null ? 'DEMO CON FEO' : 'DEMO EXECUTION',
                        style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 12),
                      // MVP: Feo anima el patrón del ejercicio cuando está en el set de 5.
                      if (feoDemo != null) ...[
                        FeoExerciseDemo(info: feoDemo, height: 200),
                        const SizedBox(height: 12),
                        Text(
                          'Referencia real del movimiento',
                          style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: Colors.white.withOpacity(0.05),
                            child: _buildRemoteDemo(mediaKey, name),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildRemoteDemo(String mediaKey, String displayName) {
    final url = _exerciseMediaUrls[mediaKey] ?? _exerciseMediaUrls[displayName];
    if (url == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (url.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.image, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Sin GIF remoto',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      },
      errorBuilder: (_, __, ___) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.imageOff, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar el GIF',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
