class AppConstants {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yehvwdoqnaezmrugopdm.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_08yY3ob_udrwAfwsYCAFcQ_Gmvhnw8g',
  );

  /// Hosted at gamelogic.dev alongside this app's other policies — see
  /// docs/policies.md for the content handed off to that repo. Verified
  /// 2026-09-19: the actual published path is /privacy-policy, not
  /// /policies as originally assumed.
  static const policiesUrl = 'https://gamelogic.dev/bookmark/privacy-policy';

  /// Empty until a Patreon page exists — screens that show this should hide
  /// the "Become a Supporter" affordance entirely while it's empty rather
  /// than show a dead link.
  static const patreonUrl = String.fromEnvironment('PATREON_URL');

  /// Personal contact for supporter shout-outs — distinct from the general
  /// support@gamelogic.dev address used for account/service issues
  /// (see SupabasePausedScreen in core/utils/supabase_error.dart).
  static const supporterContactEmail = 'ethanferrier@gamelogic.dev';
}
