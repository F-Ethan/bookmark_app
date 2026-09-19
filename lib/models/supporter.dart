/// A Patreon backer credited in the Supporters screen. Rows are managed
/// directly via the Supabase dashboard table editor — see
/// supabase/migrations/0005_supporters.sql.
class Supporter {
  final String id;
  final String displayName;
  final String? logoUrl;
  final String? linkUrl;
  final String? tier;

  const Supporter({
    required this.id,
    required this.displayName,
    this.logoUrl,
    this.linkUrl,
    this.tier,
  });

  factory Supporter.fromJson(Map<String, dynamic> json) {
    return Supporter(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      logoUrl: json['logo_url'] as String?,
      linkUrl: json['link_url'] as String?,
      tier: json['tier'] as String?,
    );
  }
}
