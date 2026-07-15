import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Wizard para crear plan nutricional (API /nutrition/create).
class NutritionWizardDialog extends StatefulWidget {
  final Future<void> Function()? onPlanCreated;

  const NutritionWizardDialog({super.key, this.onPlanCreated});

  static Future<void> show(BuildContext context, {Future<void> Function()? onPlanCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        backgroundColor: Colors.transparent,
        child: NutritionWizardDialog(onPlanCreated: onPlanCreated),
      ),
    );
  }

  @override
  State<NutritionWizardDialog> createState() => _NutritionWizardDialogState();
}

class _NutritionWizardDialogState extends State<NutritionWizardDialog> {
  int _step = 0;
  bool _isSubmitting = false;

  final _ageController = TextEditingController(text: '30');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  final _formKey = GlobalKey<FormState>();

  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _objective = 'maintenance';
  int _mealFrequency = 4;
  final Set<String> _restrictions = {};
  String _prepTime = '15-30min';
  String _budget = 'medium';

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await ApiService.createNutritionPlan({
      'age': int.tryParse(_ageController.text.trim()) ?? 30,
      'weight': double.tryParse(_weightController.text.trim()) ?? 70.0,
      'height': double.tryParse(_heightController.text.trim()) ?? 170.0,
      'gender': _gender,
      'activityLevel': _activityLevel,
      'objective': _objective,
      'mealFrequency': _mealFrequency,
      'dietaryRestrictions': _restrictions.toList(),
      'foodPreferences': <String>[],
      'foodDislikes': <String>[],
      'prepTime': _prepTime,
      'budget': _budget,
    });
    setState(() => _isSubmitting = false);

    if (result == null || result['success'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error']?.toString() ?? 'No se pudo generar el plan nutricional.'),
            backgroundColor: Colors.red,
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
          content: Text('Plan nutricional generado.'),
          backgroundColor: Color(0xFF39C34B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.apple, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Plan de alimentación',
                  style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Paso ${_step + 1} de 3', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: _buildStepBody(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_step > 0)
                TextButton(
                  onPressed: _isSubmitting ? null : () => setState(() => _step--),
                  child: Text('Atrás', style: GoogleFonts.inter(color: Colors.grey[400])),
                ),
              const Spacer(),
              if (_step < 2)
                ElevatedButton(
                  onPressed: () {
                    if (_step == 0 && !_formKey.currentState!.validate()) return;
                    setState(() => _step++);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                  child: const Text('Siguiente'),
                )
              else
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Generar plan'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Datos básicos', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            _numField(_ageController, 'Edad', 'años'),
            const SizedBox(height: 12),
            _numField(_weightController, 'Peso', 'kg'),
            const SizedBox(height: 12),
            _numField(_heightController, 'Altura', 'cm'),
            const SizedBox(height: 16),
            Text('Sexo', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _chip('male', 'Hombre', _gender, (v) => setState(() => _gender = v)),
                _chip('female', 'Mujer', _gender, (v) => setState(() => _gender = v)),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Objetivo y actividad', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            ...[
              ('fat_loss', 'Perder grasa'),
              ('muscle_gain', 'Ganar músculo'),
              ('maintenance', 'Mantenimiento'),
              ('general_health', 'Salud general'),
            ].map((e) => RadioListTile<String>(
                  dense: true,
                  activeColor: AppColors.primary,
                  title: Text(e.$2, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                  value: e.$1,
                  groupValue: _objective,
                  onChanged: (v) => setState(() => _objective = v!),
                )),
            const SizedBox(height: 8),
            Text('Nivel de actividad', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            DropdownButtonFormField<String>(
              value: _activityLevel,
              dropdownColor: AppColors.cardSolid,
              style: GoogleFonts.inter(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'sedentary', child: Text('Sedentario')),
                DropdownMenuItem(value: 'light', child: Text('Ligero')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderado')),
                DropdownMenuItem(value: 'active', child: Text('Activo')),
                DropdownMenuItem(value: 'very_active', child: Text('Muy activo')),
              ],
              onChanged: (v) => setState(() => _activityLevel = v ?? 'moderate'),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Comidas y estilo', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            const SizedBox(height: 12),
            Text('Comidas por día', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            Wrap(
              spacing: 8,
              children: [3, 4, 5, 6]
                  .map((n) => ChoiceChip(
                        label: Text('$n'),
                        selected: _mealFrequency == n,
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.inter(
                          color: _mealFrequency == n ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _mealFrequency = n),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Restricciones', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ('vegan', 'Vegano'),
                ('vegetarian', 'Vegetariano'),
                ('gluten_free', 'Sin gluten'),
                ('dairy_free', 'Sin lactosa'),
              ]
                  .map((e) => FilterChip(
                        label: Text(e.$2),
                        selected: _restrictions.contains(e.$1),
                        selectedColor: AppColors.primary.withOpacity(0.4),
                        checkmarkColor: AppColors.primary,
                        labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _restrictions.add(e.$1);
                            } else {
                              _restrictions.remove(e.$1);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Tiempo de prep.', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            DropdownButtonFormField<String>(
              value: _prepTime,
              dropdownColor: AppColors.cardSolid,
              style: GoogleFonts.inter(color: Colors.white),
              items: const [
                DropdownMenuItem(value: '<15min', child: Text('< 15 min')),
                DropdownMenuItem(value: '15-30min', child: Text('15-30 min')),
                DropdownMenuItem(value: '30-60min', child: Text('30-60 min')),
                DropdownMenuItem(value: '>60min', child: Text('> 60 min')),
              ],
              onChanged: (v) => setState(() => _prepTime = v ?? '15-30min'),
            ),
            const SizedBox(height: 12),
            Text('Presupuesto', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            DropdownButtonFormField<String>(
              value: _budget,
              dropdownColor: AppColors.cardSolid,
              style: GoogleFonts.inter(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'budget', child: Text('Económico')),
                DropdownMenuItem(value: 'medium', child: Text('Medio')),
                DropdownMenuItem(value: 'premium', child: Text('Premium')),
              ],
              onChanged: (v) => setState(() => _budget = v ?? 'medium'),
            ),
          ],
        );
    }
  }

  Widget _numField(TextEditingController c, String label, String suffix) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: GoogleFonts.inter(color: Colors.grey[500]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requerido';
        if (double.tryParse(v.trim()) == null) return 'Número inválido';
        return null;
      },
    );
  }

  Widget _chip(String value, String label, String selected, ValueChanged<String> onTap) {
    final isOn = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isOn,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.inter(color: isOn ? Colors.black : Colors.white, fontWeight: FontWeight.w600),
      onSelected: (_) => onTap(value),
    );
  }
}
