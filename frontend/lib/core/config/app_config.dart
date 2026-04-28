class AppConfig {
  static const _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const useSupabaseBackend = bool.fromEnvironment(
    'USE_SUPABASE_BACKEND',
    defaultValue: false,
  );

  static const supabaseProjectRef = String.fromEnvironment(
    'SUPABASE_PROJECT_REF',
    defaultValue: 'slotoylryvbujmtesswt',
  );

  static String get supabaseEdgeApiBaseUrl =>
      'https://$supabaseProjectRef.supabase.co/functions/v1/api';

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    if (useSupabaseBackend) {
      return supabaseEdgeApiBaseUrl;
    }
    // Default to the Azure App Service URL when no override or Supabase backend is used.
    // This ensures the app connects to the deployed backend.
    return 'https://flowsyncpro-final.azurewebsites.net';
  }

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '881175746642-1ae42aot5ln1upsonf0ht6fb98bkmg47.apps.googleusercontent.com',
  );

  static const enableDemoAuth = bool.fromEnvironment(
    'ENABLE_DEMO_AUTH',
    defaultValue: false,
  );

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isSupabaseEdgeBackend =>
      apiBaseUrl.contains('.supabase.co/functions/v1/api');

  static String get socketUrl => apiBaseUrl;
  static const pollInterval = Duration(seconds: 10);
}
