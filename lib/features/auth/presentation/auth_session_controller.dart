import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_model.dart';
import '../domain/auth_repository.dart';

enum AuthSessionStatus { restoring, authenticated, unauthenticated }

final class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthSessionState.restoring()
    : this(status: AuthSessionStatus.restoring);

  const AuthSessionState.unauthenticated({String? errorMessage})
    : this(
        status: AuthSessionStatus.unauthenticated,
        errorMessage: errorMessage,
      );

  const AuthSessionState.authenticated(UserModel user)
    : this(status: AuthSessionStatus.authenticated, user: user);

  final AuthSessionStatus status;
  final UserModel? user;
  final bool isSubmitting;
  final String? errorMessage;

  AuthSessionState submitting() =>
      AuthSessionState(status: status, user: user, isSubmitting: true);
}

final class AuthSessionController extends StateNotifier<AuthSessionState> {
  AuthSessionController(
    this._repository, {
    required Stream<void> sessionExpired,
  }) : super(const AuthSessionState.restoring()) {
    _sessionSubscription = sessionExpired.listen((_) {
      state = const AuthSessionState.unauthenticated(
        errorMessage: 'Сессия истекла. Войдите снова.',
      );
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<void> _sessionSubscription;

  Future<void> restore() async {
    state = const AuthSessionState.restoring();
    try {
      final user = await _repository.restoreSession();
      state = user == null
          ? const AuthSessionState.unauthenticated()
          : AuthSessionState.authenticated(user);
    } on Object catch (error) {
      state = AuthSessionState.unauthenticated(errorMessage: '$error');
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.submitting();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthSessionState.authenticated(user);
    } on Object catch (error) {
      state = AuthSessionState.unauthenticated(errorMessage: '$error');
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String familyName,
  }) async {
    state = state.submitting();
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        familyName: familyName,
      );
      state = AuthSessionState.authenticated(user);
    } on Object catch (error) {
      state = AuthSessionState.unauthenticated(errorMessage: '$error');
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthSessionState.unauthenticated();
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = AuthSessionState(
      status: state.status,
      user: state.user,
      isSubmitting: state.isSubmitting,
    );
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    super.dispose();
  }
}
