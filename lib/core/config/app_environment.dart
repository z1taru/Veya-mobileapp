enum AppEnvironment { dev, staging, prod }

final class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (value) => value.name == environmentName,
        orElse: () => AppEnvironment.dev,
      ),
      apiBaseUrl: apiBaseUrl,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
}
