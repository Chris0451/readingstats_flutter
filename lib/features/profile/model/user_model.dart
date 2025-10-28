// lib/features/profile/model/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String name;
  final String surname;
  final String email;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    this.createdAt,
  });

  String get usernameLower => username.trim().toLowerCase();

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserModel(
      uid: (d['uid'] ?? doc.id) as String,
      username: (d['username'] ?? '') as String,
      name: (d['name'] ?? '') as String,
      surname: (d['surname'] ?? '') as String,
      email: (d['email'] ?? '') as String,
      createdAt: d['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'usernameLower': usernameLower,
        'name': name,
        'surname': surname,
        'email': email,
        'createdAt': createdAt,
      };

  UserModel copyWith({
    String? username,
    String? name,
    String? surname,
    String? email,
  }) =>
      UserModel(
        uid: uid,
        username: username ?? this.username,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        email: email ?? this.email,
        createdAt: createdAt,
      );
}
