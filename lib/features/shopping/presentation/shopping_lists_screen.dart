import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import 'shopping_providers.dart';

final class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый список'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Название'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final family = ref.read(currentFamilyProvider).valueOrNull;
    final user = ref.read(authSessionControllerProvider).user;
    if (family == null || user == null) return;
    try {
      final id = await ref
          .read(shoppingListRepositoryProvider)
          .createList(familyId: family.id, createdById: user.id, name: name);
      if (context.mounted) context.push(AppRoutes.shoppingList(id));
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Списки покупок')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createList(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Новый список'),
      ),
      body: lists.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Создайте первый список покупок'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final list = items[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.shopping_basket_outlined),
                      title: Text(list.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(AppRoutes.shoppingList(list.id)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
