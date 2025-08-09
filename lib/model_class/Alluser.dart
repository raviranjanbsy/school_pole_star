import 'package:equatable/equatable.dart';

class Alluser extends Equatable {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String status; // e.g., 'active', 'inactive'
  final String username;
  final String? classId;
  final String? className;
  final String? image; // Optional image URL
  final String? fcmToken; // Firebase Cloud Messaging token
  final bool isSelected; // For UI selection, not persisted

  const Alluser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.username,
    this.classId,
    this.className,
    this.image,
    this.fcmToken,
    this.isSelected = false, // Default to not selected
  });

  factory Alluser.fromMap(Map<String, dynamic> map, String uid) {
    return Alluser(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      status: map['status'] as String? ?? '',
      username: map['username'] as String? ?? '',
      classId: map['classId'] as String?,
      className: map['className'] as String?,
      image: map['image'] as String?,
      fcmToken: map['fcmToken'] as String?,
      // isSelected is not from map, it's a UI state
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'status': status,
      'username': username,
      'classId': classId,
      'className': className,
      'image': image,
      'fcmToken': fcmToken,
    };
  }

  // Method to create a copy with updated isSelected status
  Alluser copyWith({
    String? classId,
    String? className,
    String? fcmToken,
    bool? isSelected,
  }) {
    return Alluser(
      uid: uid,
      email: email,
      name: name,
      role: role,
      status: status,
      username: username,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      fcmToken: fcmToken ?? this.fcmToken,
      image: image,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        role,
        status,
        username,
        classId,
        className,
        image,
        fcmToken,
        isSelected
      ];
}
