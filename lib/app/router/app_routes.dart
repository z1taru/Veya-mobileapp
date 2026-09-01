abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const family = '/family';
  static const familyInvite = '/family/invite';
  static const taskNew = '/tasks/new';
  static const shopping = '/shopping';
  static const activity = '/activity';

  static String task(String taskId) => '/tasks/$taskId';
  static String taskEdit(String taskId) => '/tasks/$taskId/edit';
  static String shoppingList(String listId) => '/shopping/$listId';
}
