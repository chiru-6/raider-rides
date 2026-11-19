class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  /// Builds a user from a TTU email. The id comes from the email, so signing
  /// in again with the same email gets the same rides back.
  factory AppUser.fromEmail({required String name, required String email}) {
    final normalized = email.trim().toLowerCase();
    final local = normalized.split('@').first.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return AppUser(id: 'u_$local', name: name.trim(), email: normalized);
  }

  final String id;
  final String name;
  final String email;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}
