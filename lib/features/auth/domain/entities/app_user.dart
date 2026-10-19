class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.image,
  });

  final String id;
  final String email;
  final String? name;
  final String? image;

  String get displayName => (name?.trim().isNotEmpty ?? false) ? name! : email;

  String get initial =>
      displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase();
}
