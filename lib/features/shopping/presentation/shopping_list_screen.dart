import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/shopping_models.dart';
import 'shopping_providers.dart';

final class ShoppingListScreen extends ConsumerWidget {
  const ShoppingListScreen({required this.listId, super.key});

  final String listId;

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final draft = await showDialog<ShoppingItemDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить покупку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Название *'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Количество'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: 'Единица'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              ShoppingItemDraft(
                name: nameController.text,
                quantity: double.tryParse(
                  quantityController.text.replaceFirst(',', '.'),
                ),
                unit: unitController.text,
              ),
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    if (draft == null || !context.mounted) return;
    final user = ref.read(authSessionControllerProvider).user;
    if (user == null) return;
    try {
      await ref
          .read(shoppingListRepositoryProvider)
          .addItem(listId: listId, createdById: user.id, draft: draft);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(shoppingListProvider(listId));
    final items = ref.watch(shoppingItemsProvider(listId));
    final user = ref.watch(authSessionControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: Text(list.valueOrNull?.name ?? 'Покупки')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Покупка'),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Ошибка: $error')),
        data: (values) => values.isEmpty
            ? const Center(child: Text('Список пока пуст'))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final item = values[index];
                  final amount = [
                    if (item.quantity != null) _formatQuantity(item.quantity!),
                    if (item.unit != null) item.unit!,
                  ].join(' ');
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: const Icon(Icons.delete_outline),
                    ),
                    onDismissed: (_) => ref
                        .read(shoppingListRepositoryProvider)
                        .deleteItem(item.id),
                    child: CheckboxListTile(
                      value: item.checked,
                      title: Text(
                        item.name,
                        style: item.checked
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: amount.isEmpty ? null : Text(amount),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: user == null
                          ? null
                          : (checked) => ref
                                .read(shoppingListRepositoryProvider)
                                .setItemChecked(
                                  id: item.id,
                                  checked: checked ?? false,
                                  currentUserId: user.id,
                                ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

String _formatQuantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
