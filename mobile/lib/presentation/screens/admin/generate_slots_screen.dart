import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla para generar slots de disponibilidad masivamente.
/// El admin selecciona cancha, rango de fechas y horarios, y se generan slots.
class GenerateSlotsScreen extends ConsumerStatefulWidget {
  const GenerateSlotsScreen({super.key, required this.courtId, required this.courtName});
  final String courtId;
  final String courtName;

  @override
  ConsumerState<GenerateSlotsScreen> createState() => _GenerateSlotsScreenState();
}

class _GenerateSlotsScreenState extends ConsumerState<GenerateSlotsScreen> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _slotDurationMinutes = 60;
  List<bool> _selectedDays = [true, true, true, true, true, true, true]; // L-D
  bool _isGenerating = false;
  int _generatedCount = 0;

  final _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _generatedCount = 0;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final slots = <Map<String, dynamic>>[];

      // Iterar por cada día en el rango
      var currentDate = _startDate;
      while (!currentDate.isAfter(_endDate)) {
        // Verificar si este día de la semana está seleccionado
        final weekday = currentDate.weekday; // 1=Mon, 7=Sun
        if (_selectedDays[weekday - 1]) {
          // Generar slots para este día
          var slotStart = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            _startTime.hour,
            _startTime.minute,
          );
          final dayEnd = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            _endTime.hour,
            _endTime.minute,
          );

          while (slotStart.add(Duration(minutes: _slotDurationMinutes)).isBefore(dayEnd) ||
              slotStart.add(Duration(minutes: _slotDurationMinutes)).isAtSameMomentAs(dayEnd)) {
            final slotEnd = slotStart.add(Duration(minutes: _slotDurationMinutes));
            slots.add({
              'court_id': widget.courtId,
              'start_time': slotStart.toUtc().toIso8601String(),
              'end_time': slotEnd.toUtc().toIso8601String(),
              'status': 'available',
            });
            slotStart = slotEnd;
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      if (slots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se generaron slots con la configuración actual')),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // Verificar duplicados: obtener slots existentes en el rango
      final existingSlots = await client
          .from(AppConstants.tableSlots)
          .select('start_time')
          .eq('court_id', widget.courtId)
          .gte('start_time', _startDate.toUtc().toIso8601String())
          .lte('start_time', _endDate.add(const Duration(days: 1)).toUtc().toIso8601String());

      final existingTimes = (existingSlots as List)
          .map((s) => s['start_time'] as String)
          .toSet();

      // Filtrar slots que ya existen
      final newSlots = slots
          .where((s) => !existingTimes.contains(s['start_time']))
          .toList();

      if (newSlots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos los slots ya existen para este rango')),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // Insertar en lotes de 50
      for (var i = 0; i < newSlots.length; i += 50) {
        final batch = newSlots.sublist(i, i + 50 > newSlots.length ? newSlots.length : i + 50);
        await client.from(AppConstants.tableSlots).insert(batch);
      }

      setState(() => _generatedCount = newSlots.length);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡${newSlots.length} slots generados! (${slots.length - newSlots.length} duplicados omitidos)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('[SLOTS] Error generating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }

    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM', 'es_CO');
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    final selectedDaysCount = _selectedDays.where((d) => d).length;
    final slotsPerDay =
        ((_endTime.hour * 60 + _endTime.minute) - (_startTime.hour * 60 + _startTime.minute)) ~/
            _slotDurationMinutes;
    final estimatedSlots = (totalDays * selectedDaysCount / 7 * slotsPerDay).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Generar slots')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cancha info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(widget.courtName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rango de fechas
            const Text('Rango de fechas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text('${dateFmt.format(_startDate)} — ${dateFmt.format(_endDate)}'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 20),

            // Días de la semana
            const Text('Días de la semana',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: List.generate(7, (i) {
                return FilterChip(
                  label: Text(_dayNames[i]),
                  selected: _selectedDays[i],
                  onSelected: (v) => setState(() => _selectedDays[i] = v),
                  selectedColor: AppTheme.primary.withOpacity(0.2),
                  checkmarkColor: AppTheme.primary,
                );
              }),
            ),
            const SizedBox(height: 20),

            // Horarios
            const Text('Horario',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text('Desde: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text('Hasta: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Duración del slot
            const Text('Duración de cada slot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 60, label: Text('1h')),
                ButtonSegment(value: 90, label: Text('1.5h')),
                ButtonSegment(value: 120, label: Text('2h')),
              ],
              selected: {_slotDurationMinutes},
              onSelectionChanged: (v) =>
                  setState(() => _slotDurationMinutes = v.first),
            ),
            const SizedBox(height: 24),

            // Estimación
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Slots estimados:'),
                  Text('~$estimatedSlots',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_generatedCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('$_generatedCount slots generados',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            // Botón generar
            ElevatedButton.icon(
              onPressed: (_isGenerating || _generatedCount > 0) ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_generatedCount > 0 ? Icons.check : Icons.auto_awesome),
              label: Text(_isGenerating
                  ? 'Generando...'
                  : _generatedCount > 0
                      ? 'Slots generados ✓'
                      : 'Generar slots'),
            ),
          ],
        ),
      ),
    );
  }
}
