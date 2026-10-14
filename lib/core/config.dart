/// Build-time configuration (`--dart-define`). No secrets live in the app.
///
///   flutter run --dart-define=API_URL=https://api.latoscanapizzeria.es
class AppConfig {
  /// Local development API via USB: run `adb reverse tcp:4000 tcp:4000`.
  /// Override API_URL for LAN, emulator, or production builds.
  static const apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:4000',
  );

  /// Public website, for legal pages opened in the browser.
  static const websiteUrl = String.fromEnvironment(
    'WEBSITE_URL',
    defaultValue: 'https://www.latoscanapizzeria.es',
  );

  /// API contract the app was built against (project-docs/api/openapi.v1.json).
  static const apiContractVersion = '1.3.0';

  static const timezone = 'Europe/Madrid';
}
