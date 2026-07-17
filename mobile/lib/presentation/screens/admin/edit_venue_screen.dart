import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class EditVenueScreen extends ConsumerStatefulWidget {
  const EditVenueScreen({
    super.key,
    required this.venueId,
    required this.initialData,
  });
  final String venueId;
  final Map<String, dynamic> initialData;

  @override
  ConsumerState<EditVenueScreen> createState() => _EditVenueScreenState();
}

class _EditVenueScreenState extends ConsumerState<EditVenueScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData['name'] as String? ?? '');
    _addressCtrl = TextEditingController(text: widget.initialData['address'] as String? ?? '');
    _latCtrl = TextEditingController(text: (widget.initialData['lat'] ?? '').toString());
    _lngCtrl = TextEditingController(text: (widget.initialData['lng'] ?? '').toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from(AppConstants.tableVenues).update({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'lat': double.tryParse(_latCtrl.text),
        'lng': double.tryParse(_lngCtrl.text),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.venueId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sede actualizada'), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text('Editar sede')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.business), border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _latCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Latitud', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  controller: _lngCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Longitud', border: OutlineInputBorder()),
                )),
              ]),
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
