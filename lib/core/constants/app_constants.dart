class AppConstants {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yehvwdoqnaezmrugopdm.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_08yY3ob_udrwAfwsYCAFcQ_Gmvhnw8g',
  );
}
