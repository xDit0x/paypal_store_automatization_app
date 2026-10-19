class AppUser {
  final String id;
  final String? email;
  final String? storeName;

  const AppUser({required this.id, this.email, this.storeName});

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
