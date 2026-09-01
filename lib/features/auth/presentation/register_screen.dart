import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import 'auth_providers.dart';

final class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _familyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _familyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authSessionControllerProvider.notifier)
        .register(
          fullName: _nameController.text.trim(),
          familyName: _familyController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authSessionControllerProvider);
    return AuthScaffold(
      title: 'Создайте свой Дом',
      subtitle: 'Заведите семейное пространство и пригласите близких позже.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Ваше имя',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _required(value, 'Введите ваше имя'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _familyController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Название семьи',
                hintText: 'Например, Семья Ибраевых',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) => _required(value, 'Введите название семьи'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Пароль',
                helperText: 'Минимум 6 символов',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Пароль должен содержать минимум 6 символов'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmationController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Повторите пароль',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) => value != _passwordController.text
                  ? 'Пароли не совпадают'
                  : null,
            ),
            if (auth.errorMessage case final message?) ...[
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: auth.isSubmitting ? null : _submit,
              child: auth.isSubmitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать аккаунт'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.isSubmitting
                  ? null
                  : () => context.go(AppRoutes.login),
              child: const Text('У меня уже есть аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value, String message) =>
    value == null || value.trim().isEmpty ? message : null;

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Введите email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Проверьте формат email';
  }
  return null;
}
