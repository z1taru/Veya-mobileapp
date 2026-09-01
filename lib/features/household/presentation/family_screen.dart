import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/models/family_model.dart';
import 'family_providers.dart';

final class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(currentFamilyProvider);
    final refreshState = ref.watch(householdControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Семья')),
      floatingActionButton: familyAsync.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.familyInvite),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Пригласить'),
            ),
      body: RefreshIndicator(
        onRefresh: ref.read(householdControllerProvider.notifier).refresh,
        child: familyAsync.when(
          loading: () =>
              const _ScrollableMessage(child: CircularProgressIndicator()),
          error: (error, _) => _ScrollableMessage(
            child: Text('Не удалось загрузить семью\n$error'),
          ),
          data: (family) {
            if (family == null) {
              return _ScrollableMessage(
                child: Text(
                  refreshState.hasError
                      ? 'Не удалось загрузить семью\n${refreshState.error}'
                      : 'Семья пока не найдена',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return _FamilyBody(family: family);
          },
        ),
      ),
    );
  }
}

final class _FamilyBody extends ConsumerWidget {
  const _FamilyBody({required this.family});

  final FamilyModel family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider(family.id));
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Text(family.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('Часовой пояс: ${family.timeZone}'),
        const SizedBox(height: 20),
        Text('Участники', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        members.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Не удалось загрузить участников: $error'),
          data: (items) => Column(
            children: [
              for (final member in items)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        member.fullName.trim().isEmpty
                            ? '?'
                            : member.fullName.trim()[0].toUpperCase(),
                      ),
                    ),
                    title: Text(member.fullName),
                    subtitle: Text(member.email),
                    trailing: Text(member.role.label),
                  ),
                ),
              if (items.isEmpty) const Text('В семье пока нет участников'),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: Center(child: child),
      ),
    ],
  );
}
