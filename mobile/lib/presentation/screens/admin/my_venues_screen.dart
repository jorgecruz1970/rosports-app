import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Provider de venues del admin actual
final myVenuesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final data = await client
      .from(AppConstants.tableVenues)
      .select('''
        id, name, address, is_active,
        courts(id, name, sport_id, price_per_hour, is_active, sports(name))
      ''')
      .eq('owner_user_id', userId)
      .order('name');

  return List<Map<String, dynamic>>.from(data);
});

class MyVenuesScreen extends ConsumerWidget {
  const MyVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(myVenuesProvider);
    final moneyFmt = NumberFormat('#,###', 'es_CO');

    return Scaffold(
      appBar: AppBar(title: const Text('Mis sedes y canchas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminCreateVenue),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva sede'),
      ),
      body: venuesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (venues) {
          if (venues.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No tienes sedes registradas',
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  const Text('Crea tu primera sede para agregar canchas',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => ref.invalidate(myVenuesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              itemBuilder: (_, i) {
                final venue = venues[i];
                final courts = venue['courts'] as List? ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Venue header
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.business,
                                  color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(venue['name'] as String,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(venue['address'] as String? ?? '',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),

                        // Canchas
                        if (courts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Sin canchas aún',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          )
                        else
                          ...courts.map((court) {
                            final sport =
                                court['sports'] as Map<String, dynamic>? ?? {};
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.sports_soccer,
                                  color: AppTheme.primary, size: 20),
                              title: Text(court['name'] as String? ?? 'Cancha'),
                              subtitle: Text(sport['name'] as String? ?? ''),
                              trailing: Text(
                                '\$${moneyFmt.format(court['price_per_hour'])}/h',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () => context.push(
                                AppRoutes.adminSlots,
                                extra: {
                                  'courtId': court['id'] as String,
                                  'courtName': court['name'] as String? ?? 'Cancha',
                                },
                              ),
                            );
                          }),

                        const SizedBox(height: 8),
                        // Botones
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push(
                                  AppRoutes.adminCreateCourt,
                                  extra: {
                                    'venueId': venue['id'] as String,
                                    'venueName': venue['name'] as String,
                                  },
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Agregar cancha',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (courts.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Primero agrega una cancha')),
                                    );
                                    return;
                                  }
                                  context.push(
                                    AppRoutes.adminGenerateSlots,
                                    extra: {
                                      'courts': courts
                                          .map((c) => {
                                                'id': c['id'] as String,
                                                'name': c['name'] as String? ?? 'Cancha',
                                              })
                                          .toList(),
                                    },
                                  );
                                },
                                icon: const Icon(Icons.calendar_month,
                                    size: 18),
                                label: const Text('Generar slots',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
