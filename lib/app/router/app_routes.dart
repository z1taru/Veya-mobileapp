abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const family = '/family';
  static const familyInvite = '/family/invite';
  static const taskNew = '/tasks/new';

  static String taskEdit(String taskId) => '/tasks/$taskId/edit';
}
