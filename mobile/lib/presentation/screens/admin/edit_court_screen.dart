import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditCourtScreen extends ConsumerStatefulWidget {
  const EditCourtScreen({
    super.key,
    required this.courtId,
    required this.initialData,
  });
  final String courtId;
  final Map<String, dynamic> initialData;

  @override
  ConsumerState<EditCourtScreen> createState() => _EditCourtScreenState();
}

class _EditCourtScreenState extends ConsumerState<EditCourtScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late String _sportId;
  late String _surface;
  late bool _hasLights;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData['name'] as String? ?? '');
    _priceCtrl = TextEditingController(
        text: (widget.initialData['price_per_hour'] ?? '').toString());
    _sportId = widget.initialData['sport_id'] as String? ?? '22222222-0000-0000-0000-000000000001';
    _surface = widget.initialData['surface_type'] as String? ?? 'Grama sintética';
    _hasLights = (widget.initialData['lights'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from(AppConstants.tableCourts).update({
        'name': _nameCtrl.text.trim(),
        'sport_id': _sportId,
        'price_per_hour': double.parse(_priceCtrl.text.trim()),
        'surface_type': _surface,
        'lights': _hasLights,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.courtId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cancha actualizada'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar cancha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.sports_soccer), border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sportId,
                decoration: const InputDecoration(
                  labelText: 'Deporte', prefixIcon: Icon(Icons.category), border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '22222222-0000-0000-0000-000000000001', child: Text('Fútbol 5')),
                  DropdownMenuItem(value: '22222222-0000-0000-0000-000000000002', child: Text('Fútbol 7')),
                  DropdownMenuItem(value: '22222222-0000-0000-0000-000000000003', child: Text('Pádel')),
                  DropdownMenuItem(value: '22222222-0000-0000-0000-000000000004', child: Text('Baloncesto')),
                ],
                onChanged: (v) => setState(() => _sportId = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio por hora (COP)', prefixIcon: Icon(Icons.attach_money), border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v.trim()) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _surface,
                decoration: const InputDecoration(
                  labelText: 'Superficie', prefixIcon: Icon(Icons.grass), border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Grama sintética', child: Text('Grama sintética')),
                  DropdownMenuItem(value: 'Grama natural', child: Text('Grama natural')),
                  DropdownMenuItem(value: 'Pavimento', child: Text('Pavimento')),
                  DropdownMenuItem(value: 'Cemento', child: Text('Cemento')),
                  DropdownMenuItem(value: 'Arcilla', child: Text('Arcilla')),
                ],
                onChanged: (v) => setState(() => _surface = v!),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _hasLights,
                onChanged: (v) => setState(() => _hasLights = v),
                title: const Text('Tiene iluminación'),
                activeColor: AppTheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
