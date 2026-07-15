import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';

class PlanWizardDialog extends StatefulWidget {
  final Future<void> Function()? onPlanCreated;

  const PlanWizardDialog({super.key, this.onPlanCreated});

  static Future<void> show(BuildContext context, {Future<void> Function()? onPlanCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        backgroundColor: Colors.transparent,
        child: PlanWizardDialog(onPlanCreated: onPlanCreated),
      ),
    );
  }

  @override
  State<PlanWizardDialog> createState() => _PlanWizardDialogState();
}

class _PlanWizardDialogState extends State<PlanWizardDialog> {
  int _step = 0;
  bool _isSubmitting = false;
  String? _objective;
  String? _experienceLevel;
  int _daysPerWeek = 3;
  String _equipment = 'full_gym';
  String _injuries = '';
  String _preferences = '';
  String _gender = 'male';
  String _activityLevel = 'moderate';
  int _trainingTimeMinutes = 50;
  final List<String> _dietaryRestrictions = [];
  final _ageController = TextEditingController(text: '25');
  final _weightController = TextEditingController(text: '75');
  final _heightController = TextEditingController(text: '175');
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _objectives = [
    {
      'value': 'hypertrophy',
      'title': 'Ganar Músculo',
      'subtitle': 'Hipertrofia y volumen',
      'icon': LucideIcons.dumbbell,
    },
    {
      'value': 'strength',
      'title': 'Ganar Fuerza',
      'subtitle': 'Fuerza máxima',
      'icon': LucideIcons.arrowUpRight,
    },
    {
      'value': 'fat_loss',
      'title': 'Perder Grasa',
      'subtitle': 'Déficit calórico',
      'icon': LucideIcons.flame,
    },
    {
      'value': 'recomposition',
      'title': 'Recomposición',
      'subtitle': 'Músculo y definición',
      'icon': LucideIcons.scale,
    },
  ];

  final List<Map<String, dynamic>> _experiences = [
    {
      'value': 'beginner',
      'title': 'Principiante',
      'subtitle': 'Menos de 1 año',
    },
    {
      'value': 'intermediate',
      'title': 'Intermedio',
      'subtitle': '1-3 años',
    },
    {
      'value': 'advanced',
      'title': 'Avanzado',
      'subtitle': 'Más de 3 años',
    },
  ];

  final List<Map<String, dynamic>> _equipmentOptions = [
    {
      'value': 'full_gym',
      'title': 'Gimnasio Completo',
      'subtitle': 'Máquinas y barras',
    },
    {
      'value': 'dumbbells',
      'title': 'Mancuernas',
      'subtitle': 'Equipamiento limitado',
    },
    {
      'value': 'bodyweight',
      'title': 'Solo peso corporal',
      'subtitle': 'Sin pesas',
    },
    {
      'value': 'limited',
      'title': 'Equipamiento reducido',
      'subtitle': 'Bandas y mancuernas ligeras',
    },
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && (_objective == null || _experienceLevel == null)) {
      return;
    }
    if (_step == 1 && !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      if (_step < 4) {
        _step += 1;
      }
    });
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  Future<void> _submitPlan() async {
    if (_step == 1 && !_formKey.currentState!.validate()) return;
    if (_objective == null || _experienceLevel == null) return;

    setState(() => _isSubmitting = true);
    final result = await ApiService.createPlan({
      'objective': _objective!,
      'experienceLevel': _experienceLevel!,
      'age': int.tryParse(_ageController.text.trim()) ?? 25,
      'weight': double.tryParse(_weightController.text.trim()) ?? 75.0,
      'height': double.tryParse(_heightController.text.trim()) ?? 175.0,
      'daysPerWeek': _daysPerWeek,
      'equipment': _equipment,
      'injuries': _injuries.trim(),
      'preferences': _preferences.trim(),
      'gender': _gender,
      'activityLevel': _activityLevel,
      'trainingTimeMinutes': _trainingTimeMinutes,
      'dietaryRestrictions': _dietaryRestrictions,
    });

    setState(() => _isSubmitting = false);
    // API mobile devuelve { success, plan }; a veces el body de error trae success:false
    final ok = result != null &&
        (result['success'] == true || result['plan'] != null) &&
        result['error'] == null;
    if (!ok) {
      if (mounted) {
        final msg = result?['error']?.toString() ??
            'No se pudo generar el plan. Revisá conexión y backend.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    if (widget.onPlanCreated != null) {
      await widget.onPlanCreated!();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu rutina se generó correctamente.'),
          backgroundColor: Color(0xFF39C34B),
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(5, (index) {
        final isCompleted = index <= _step;
        return Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF39C34B) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.rajdhani(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOptionCard({
    required String value,
    required String title,
    required String subtitle,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF152D0E) : const Color(0xFF0D0F17),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF39C34B) : const Color(0xFF1E293B),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF39C34B).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF39C34B), size: 18),
              ),
            if (icon != null) const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.rajdhani(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey[200],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: selected ? Colors.grey[300] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _steps => [
        _buildObjectiveStep(),
        _buildPhysicalStep(),
        _buildScheduleStep(),
        _buildPreferencesStep(),
        _buildSummaryStep(),
      ];

  Widget _buildObjectiveStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepTitle('¿Cuál es tu objetivo principal?'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: _objectives.map((option) {
            final selected = _objective == option['value'];
            return _buildOptionCard(
              value: option['value'] as String,
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              icon: option['icon'] as IconData,
              selected: selected,
              onTap: () => setState(() => _objective = option['value'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _buildStepTitle('¿Cuál es tu nivel de experiencia?'),
        const SizedBox(height: 16),
        ..._experiences.map((option) {
          final selected = _experienceLevel == option['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionCard(
              value: option['value'] as String,
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              selected: selected,
              onTap: () => setState(() => _experienceLevel = option['value'] as String),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPhysicalStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle('Tu información física'),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildNumberField(controller: _ageController, label: 'Edad', suffix: 'años'),
              const SizedBox(width: 12),
              _buildNumberField(controller: _weightController, label: 'Peso', suffix: 'kg'),
              const SizedBox(width: 12),
              _buildNumberField(controller: _heightController, label: 'Altura', suffix: 'cm'),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _gender,
            dropdownColor: const Color(0xFF0F172A),
            decoration: InputDecoration(
              labelText: 'Sexo Biológico',
              labelStyle: GoogleFonts.inter(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Masculino')),
              DropdownMenuItem(value: 'female', child: Text('Femenino')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _gender = val);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _activityLevel,
            dropdownColor: const Color(0xFF0F172A),
            decoration: InputDecoration(
              labelText: 'Nivel de Actividad Diaria',
              labelStyle: GoogleFonts.inter(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            style: GoogleFonts.inter(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'sedentary', child: Text('Sedentario (Poco movimiento)')),
              DropdownMenuItem(value: 'light', child: Text('Ligero (Trabajo de pie)')),
              DropdownMenuItem(value: 'moderate', child: Text('Moderado (Activo en el día)')),
              DropdownMenuItem(value: 'active', child: Text('Activo (Gran actividad física)')),
              DropdownMenuItem(value: 'very_active', child: Text('Muy Activo (Atleta/Físico pesado)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _activityLevel = val);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Ingresa datos reales para que el plan sea personalizado.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepTitle('¿Cuántos días por semana podés entrenar?'),
        const SizedBox(height: 16),
        Text(
          'Entre 2 y 6 días',
          style: GoogleFonts.inter(color: Colors.grey[400]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _daysPerWeek.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                activeColor: const Color(0xFF39C34B),
                inactiveColor: const Color(0xFF1E293B),
                label: '$_daysPerWeek',
                onChanged: (value) {
                  setState(() => _daysPerWeek = value.toInt());
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$_daysPerWeek',
              style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '¿Qué equipo tenés disponible?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[300]),
        ),
        const SizedBox(height: 12),
        ..._equipmentOptions.map((option) {
          final selected = _equipment == option['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionCard(
              value: option['value'] as String,
              title: option['title'] as String,
              subtitle: option['subtitle'] as String,
              selected: selected,
              onTap: () => setState(() => _equipment = option['value'] as String),
            ),
          );
        }).toList(),
        const SizedBox(height: 24),
        DropdownButtonFormField<int>(
          value: _trainingTimeMinutes,
          dropdownColor: const Color(0xFF0F172A),
          decoration: InputDecoration(
            labelText: 'Tiempo disponible por día',
            labelStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: GoogleFonts.inter(color: Colors.white),
          items: const [
            DropdownMenuItem(value: 20, child: Text('20 minutos (Express)')),
            DropdownMenuItem(value: 35, child: Text('35 minutos (Corto)')),
            DropdownMenuItem(value: 50, child: Text('45-60 minutos (Estándar)')),
            DropdownMenuItem(value: 80, child: Text('Más de 60 minutos (Largo)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _trainingTimeMinutes = val);
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepTitle('¿Tenés lesiones o limitaciones?'),
          const SizedBox(height: 12),
          _buildTextArea(
            controller: TextEditingController(text: _injuries),
            hint: 'Ej: dolor de espalda baja, rodilla izquierda débil... (Opcional)',
            onChanged: (value) => _injuries = value,
          ),
          const SizedBox(height: 16),
          _buildStepTitle('Preferencias de ejercicios'),
          const SizedBox(height: 12),
          _buildTextArea(
            controller: TextEditingController(text: _preferences),
            hint: 'Ej: prefiero ejercicios compuestos, evito máquinas, me gusta el cardio... (Opcional)',
            onChanged: (value) => _preferences = value,
          ),
          const SizedBox(height: 20),
          _buildStepTitle('Restricciones Alimenticias'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'vegano', 'vegetariano', 'sin_gluten', 'sin_lactosa'
            ].map((restriction) {
              final selected = _dietaryRestrictions.contains(restriction);
              final label = restriction.replaceAll('_', ' ').toUpperCase();
              return FilterChip(
                selected: selected,
                label: Text(label, style: GoogleFonts.inter(fontSize: 12, color: selected ? Colors.white : Colors.grey[400])),
                onSelected: (bool on) {
                  setState(() {
                    if (on) {
                      _dietaryRestrictions.add(restriction);
                    } else {
                      _dietaryRestrictions.remove(restriction);
                    }
                  });
                },
                selectedColor: const Color(0xFF39C34B).withOpacity(0.2),
                checkmarkColor: const Color(0xFF39C34B),
                backgroundColor: Colors.black.withOpacity(0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Estos campos son opcionales pero ayudan a personalizar mejor la rutina.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepTitle('Resumen de tu rutina'),
        const SizedBox(height: 16),
        _buildSummaryTile('Objetivo', _objectiveText()),
        _buildSummaryTile('Nivel', _experienceText()),
        _buildSummaryTile('Edad', '${_ageController.text.trim()} años'),
        _buildSummaryTile('Peso', '${_weightController.text.trim()} kg'),
        _buildSummaryTile('Altura', '${_heightController.text.trim()} cm'),
        _buildSummaryTile('Días / semana', '$_daysPerWeek'),
        _buildSummaryTile('Equipo', _equipmentText()),
        _buildSummaryTile('Sexo Biológico', _gender == 'male' ? 'Masculino' : 'Femenino'),
        _buildSummaryTile('Actividad Diaria', _activityLevel.toUpperCase()),
        _buildSummaryTile('Tiempo diario', '$_trainingTimeMinutes min'),
        if (_dietaryRestrictions.isNotEmpty) _buildSummaryTile('Dietas', _dietaryRestrictions.join(', ').toUpperCase()),
        if (_injuries.isNotEmpty) _buildSummaryTile('Lesiones / limitaciones', _injuries),
        if (_preferences.isNotEmpty) _buildSummaryTile('Preferencias', _preferences),
        const SizedBox(height: 16),
        Text(
          'Presioná Generar rutina para crear tu plan personalizado con IA.',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return 'Requerido';
          final number = int.tryParse(text);
          if (number == null) return 'Número inválido';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[400]),
          suffixText: suffix,
          suffixStyle: GoogleFonts.inter(color: Colors.grey[400]),
          filled: true,
          fillColor: const Color(0xFF0D0F17),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF39C34B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      minLines: 4,
      maxLines: 6,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
        filled: true,
        fillColor: const Color(0xFF0D0F17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF39C34B)),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _objectiveText() {
    return _objectives.firstWhere((opt) => opt['value'] == _objective, orElse: () => {}).cast<String, dynamic>()['title'] ?? 'No definido';
  }

  String _experienceText() {
    return _experiences.firstWhere((opt) => opt['value'] == _experienceLevel, orElse: () => {}).cast<String, dynamic>()['title'] ?? 'No definido';
  }

  String _equipmentText() {
    return _equipmentOptions.firstWhere((opt) => opt['value'] == _equipment, orElse: () => {}).cast<String, dynamic>()['title'] ?? 'Sin equipo';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu Rutina Personalizada – Paso ${_step + 1} de 5',
                style: GoogleFonts.rajdhani(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: _steps[_step],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _step == 0 || _isSubmitting ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF1E293B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _step < 4
                          ? _nextStep
                          : _submitPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39C34B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.0),
                        )
                      : Text(
                          _step < 4 ? 'Siguiente' : 'Generar rutina',
                          style: const TextStyle(color: Colors.black),
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
