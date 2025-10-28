// lib/features/profile/model/friends_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String uid;
  final String name;
  final String surname;
  final String username;
  final String email;

  const Friend({
    required this.uid,
    required this.name,
    required this.surname,
    required this.username,
    required this.email,
  });

  factory Friend.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Friend(
      uid: (d['uid'] ?? doc.id) as String,
      name: (d['name'] ?? '') as String,
      surname: (d['surname'] ?? '') as String,
      username: (d['username'] ?? '') as String,
      email: (d['email'] ?? '') as String,
    );
  }

  String get fullName => '${name} ${surname}'.trim();

  bool matches(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return name.toLowerCase().contains(s) ||
        surname.toLowerCase().contains(s) ||
        username.toLowerCase().contains(s);
  }
}

class FriendRequest {
  final String id;
  final String fromUid;
  final String toUid;
  final String status;
  final Timestamp? timestamp;
  final String message;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    this.timestamp,
    this.message = '',
  });

  factory FriendRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FriendRequest(
      id: doc.id,
      fromUid: (d['fromUid'] ?? '') as String,
      toUid: (d['toUid'] ?? '') as String,
      status: (d['status'] ?? 'pending') as String,
      timestamp: d['timestamp'] as Timestamp?,
      message: (d['message'] ?? '') as String,
    );
  }
}

enum UserRelationshipStatus { notFriend, pending, isFriend }

class FriendBook {
  final String id;
  final String title;
  final String volumeId;
  final List<String> authors;
  final String? thumbnail;
  final List<String> categories;
  final int? pageCount;
  final String? description;
  final int? pageInReading;
  final String status;
  final int? totalReadSeconds;
  final String? isbn13;
  final String? isbn10;

  const FriendBook({
    required this.id,
    required this.volumeId,
    required this.title,
    this.authors = const [],
    this.thumbnail,
    this.categories = const [],
    this.pageCount,
    this.description,
    this.pageInReading,
    this.status = 'TO_READ',
    this.totalReadSeconds,
    this.isbn13,
    this.isbn10,
  });

  factory FriendBook.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return FriendBook(
      id: doc.id,
      volumeId: (d['volumeId'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      authors: (d['authors'] as List?)?.cast<String>() ?? const [],
      thumbnail: d['thumbnail'] as String?,
      categories: (d['categories'] as List?)?.cast<String>() ?? const [],
      pageCount: (d['pageCount'] as num?)?.toInt(),
      description: d['description'] as String?,
      pageInReading: (d['pageInReading'] as num?)?.toInt(),
      status: (d['status'] ?? 'TO_READ') as String,
      totalReadSeconds: (d['totalReadSeconds'] as num?)?.toInt(),
      isbn13: d['isbn13'] as String?,
      isbn10: d['isbn10'] as String?,
    );
  }
}
