import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

/// Bottom sheet para registrar comidas con texto libre usando IA
class SmartLogBottomSheet extends StatefulWidget {
  final VoidCallback? onLogged;
  const SmartLogBottomSheet({super.key, this.onLogged});

  static Future<void> show(BuildContext context, {VoidCallback? onLogged}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartLogBottomSheet(onLogged: onLogged),
    );
  }

  @override
  State<SmartLogBottomSheet> createState() => _SmartLogBottomSheetState();
}

class _SmartLogBottomSheetState extends State<SmartLogBottomSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _analyze() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _result = null; _error = null; });
    final res = await ApiService.smartLog(_controller.text.trim());
    if (!mounted) return;
    if (res != null && res['success'] == true) {
      setState(() { _result = res['data'] as Map<String, dynamic>?; _isLoading = false; });
    } else {
      setState(() { _error = 'No se pudo analizar. Describí mejor la comida.'; _isLoading = false; });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF39C34B), Color(0xFF2EA043)]),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cargar comida con IA', style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Describí lo que comiste', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: "Desayuné dos huevos revueltos, una tostada integral y un café con leche"',
                hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyze,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(_isLoading ? 'Analizando...' : 'Analizar con IA', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39C34B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF39C34B).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF39C34B), size: 18),
                        const SizedBox(width: 8),
                        Text('Alimentos detectados', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_result!['foods'] as List? ?? []).map((food) {
                      final f = food as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${f['name']} (${f['quantity']} ${f['unit']})', style: GoogleFonts.inter(color: Colors.white, fontSize: 13))),
                            Text('${f['calories']} kcal', style: GoogleFonts.inter(color: const Color(0xFF39C34B), fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MacroChip('Kcal', '${_result!['totalCalories']}', const Color(0xFFFFB347)),
                        _MacroChip('Prot', '${_result!['totalProtein']}g', const Color(0xFF39C34B)),
                        _MacroChip('Carbs', '${_result!['totalCarbs']}g', const Color(0xFF6B8EFF)),
                        _MacroChip('Grasas', '${_result!['totalFats']}g', const Color(0xFFFF6B6B)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        widget.onLogged?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39C34B),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Guardar comida', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
      ],
    );
  }
}

/// Bottom sheet para generar recetas con ingredientes disponibles
class FridgeRecipeBottomSheet extends StatefulWidget {
  const FridgeRecipeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FridgeRecipeBottomSheet(),
    );
  }

  @override
  State<FridgeRecipeBottomSheet> createState() => _FridgeRecipeBottomSheetState();
}

class _FridgeRecipeBottomSheetState extends State<FridgeRecipeBottomSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _recipe;
  String? _error;

  Future<void> _generate() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _isLoading = true; _recipe = null; _error = null; });
    final res = await ApiService.generateFridgeRecipe(_controller.text.trim());
    if (!mounted) return;
    if (res != null && res['success'] == true) {
      setState(() { _recipe = res['recipe'] as Map<String, dynamic>?; _isLoading = false; });
    } else {
      setState(() { _error = 'No se pudo generar la receta. Intentá de nuevo.'; _isLoading = false; });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF8C00)]),
                  ),
                  child: const Icon(Icons.kitchen, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Qué hay en tu heladera?', style: GoogleFonts.rajdhani(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Generamos una receta saludable al instante', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 2,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ej: "atún, tomate, arroz frío, huevo, cebolla"',
                hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
              label: Text(_isLoading ? 'Generando receta...' : 'Generar receta con IA',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
            ],
            if (_recipe != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_recipe!['title'] ?? 'Receta', style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFFFB347), size: 16),
                        const SizedBox(width: 4),
                        Text(_recipe!['prepTime'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Ingredientes', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFFB347))),
                    const SizedBox(height: 6),
                    ...(_recipe!['ingredients'] as List? ?? []).map((ing) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFFFFB347)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ing.toString(), style: GoogleFonts.inter(fontSize: 13, color: Colors.white70))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 14),
                    Text('Preparación', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFFFB347))),
                    const SizedBox(height: 6),
                    ...(_recipe!['steps'] as List? ?? []).asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFB347)),
                            child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(e.value.toString(), style: GoogleFonts.inter(fontSize: 13, color: Colors.white70))),
                        ],
                      ),
                    )),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MacroChip('Kcal', '${(_recipe!['macros'] as Map?)?['calories'] ?? 0}', const Color(0xFFFFB347)),
                        _MacroChip('Prot', '${(_recipe!['macros'] as Map?)?['protein'] ?? 0}g', const Color(0xFF39C34B)),
                        _MacroChip('Carbs', '${(_recipe!['macros'] as Map?)?['carbs'] ?? 0}g', const Color(0xFF6B8EFF)),
                        _MacroChip('Grasas', '${(_recipe!['macros'] as Map?)?['fats'] ?? 0}g', const Color(0xFFFF6B6B)),
                      ],
                    ),
                    if (_recipe!['tip'] != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF39C34B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Text('🐾', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_recipe!['tip'].toString(), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[300], fontStyle: FontStyle.italic))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
