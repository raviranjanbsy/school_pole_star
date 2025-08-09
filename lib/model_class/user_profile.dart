class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? image;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.image,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      name: map['name'] ?? 'No Name',
      email: map['email'] ?? 'No Email',
      role: map['role'] ?? 'unknown',
      status: map['status'] ?? 'inactive',
      image: map['image'],
    );
  }
}
