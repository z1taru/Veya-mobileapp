import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/family_model.dart';
import '../../household/presentation/family_providers.dart';
import 'activity_providers.dart';

final class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(currentFamilyProvider).valueOrNull;
    final members = family == null
        ? const AsyncValue<List<FamilyMemberModel>>.data([])
        : ref.watch(familyMembersProvider(family.id));
    final events = ref.watch(activityEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Активность')),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Событий пока нет'));
          }
          final memberItems = members.valueOrNull ?? const [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final event = items[index];
              final actor = memberItems
                  .where((member) => member.userId == event.actorId)
                  .firstOrNull;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.history, size: 20),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    [
                      if (event.description != null) event.description!,
                      actor?.fullName ?? 'Veya',
                      DateFormat('dd.MM.yyyy, HH:mm')
                          .format(event.createdAt.toLocal()),
                    ].join(' · '),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
