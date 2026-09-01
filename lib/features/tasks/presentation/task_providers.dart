import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../household/presentation/family_providers.dart';
import '../data/local_task_repository.dart';
import '../domain/task_models.dart';
import '../domain/task_repository.dart';

final uuidProvider = Provider<Uuid>((ref) => const Uuid());

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return LocalTaskRepository(
    ref.watch(databaseProvider),
    ref.watch(uuidProvider),
  );
});

final taskListFilterProvider = StateProvider<TaskListFilter>(
  (ref) => const TaskListFilter(),
);

final visibleTasksProvider = StreamProvider.autoDispose<List<TaskModel>>((ref) {
  final family = ref.watch(currentFamilyProvider).valueOrNull;
  final user = ref.watch(authSessionControllerProvider).user;
  final filter = ref.watch(taskListFilterProvider);
  if (family == null || user == null) return Stream.value(const []);
  return ref
      .watch(taskRepositoryProvider)
      .watchTasks(familyId: family.id, currentUserId: user.id, filter: filter);
});

final taskByIdProvider = FutureProvider.autoDispose.family<TaskModel?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).getTask(id),
);

final taskActionsProvider =
    StateNotifierProvider<TaskActionsController, AsyncValue<void>>((ref) {
      return TaskActionsController(ref.watch(taskRepositoryProvider));
    });

final taskEditorProvider = StateNotifierProvider.autoDispose
    .family<TaskEditorController, TaskEditorState, String?>((ref, taskId) {
      final controller = TaskEditorController(
        ref.watch(taskRepositoryProvider),
        taskId,
        ref.watch(currentFamilyProvider).valueOrNull?.id,
        ref.watch(authSessionControllerProvider).user?.id,
      );
      controller.load();
      return controller;
    });

final class TaskActionsController extends StateNotifier<AsyncValue<void>> {
  TaskActionsController(this._repository) : super(const AsyncData(null));

  final TaskRepository _repository;

  Future<void> updateStatus(String id, TaskStatus status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateStatus(id, status));
  }
}

final class TaskEditorState {
  const TaskEditorState({
    this.draft = const TaskDraft(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final TaskDraft draft;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  TaskEditorState copyWith({
    TaskDraft? draft,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _unset,
  }) => TaskEditorState(
    draft: draft ?? this.draft,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

final class TaskEditorController extends StateNotifier<TaskEditorState> {
  TaskEditorController(
    this._repository,
    this._taskId,
    this._familyId,
    this._currentUserId,
  ) : super(TaskEditorState(isLoading: _taskId != null));

  final TaskRepository _repository;
  final String? _taskId;
  final String? _familyId;
  final String? _currentUserId;

  Future<void> load() async {
    if (_taskId == null) return;
    try {
      final task = await _repository.getTask(_taskId);
      if (task == null) throw StateError('Задача не найдена');
      state = TaskEditorState(draft: TaskDraft.fromTask(task));
    } on Object catch (error) {
      state = TaskEditorState(errorMessage: '$error');
    }
  }

  void update(TaskDraft draft) {
    state = state.copyWith(draft: draft, errorMessage: null);
  }

  void change(TaskDraft Function(TaskDraft draft) transform) {
    update(transform(state.draft));
  }

  Future<bool> save() async {
    final errors = state.draft.validate();
    if (errors.isNotEmpty) {
      state = state.copyWith(errorMessage: errors.first);
      return false;
    }
    if (_taskId == null && (_familyId == null || _currentUserId == null)) {
      state = state.copyWith(errorMessage: 'Семья или пользователь не найдены');
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      if (_taskId == null) {
        await _repository.createTask(
          familyId: _familyId!,
          createdById: _currentUserId!,
          draft: state.draft,
        );
      } else {
        await _repository.updateTask(_taskId, state.draft);
      }
      state = state.copyWith(isSaving: false);
      return true;
    } on Object catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: '$error');
      return false;
    }
  }
}

const _unset = Object();
