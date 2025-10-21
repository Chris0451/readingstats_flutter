import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:readingstats_flutter/features/home/data/home_repository.dart';
import 'package:readingstats_flutter/features/home/model/ui_home_book.dart';
import 'package:readingstats_flutter/features/shelves/model/reading_status.dart';
import 'package:readingstats_flutter/features/shelves/model/user_book.dart';

class FirestoreHomeRepository implements HomeRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreHomeRepository(this._db, this._auth);

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Nessun utente autenticato');
    return u.uid;
    }

  CollectionReference<Map<String, dynamic>> get _booksCol =>
      _db.collection('users').doc(_uid).collection('books');

  @override
  Stream<List<UiHomeBook>> observeReadingBooks() {
    return _booksCol
        .where('status', isEqualTo: "READING")
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = data['id'] ?? d.id;
              return UiHomeBook.fromJson(data);
            }).toList());
  }

  @override
  Future<void> updatePagesRead(String bookId, int pages) async {
    await _booksCol.doc(bookId).set({'pageInReading': pages}, SetOptions(merge: true));
  }

  @override
  Future<void> setStatus({
    required String bookId,
    required String status,
    required UserBook payload,
  }) async {
    final data = payload.copyWith(status: status).toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _booksCol.doc(bookId).set(data, SetOptions(merge: true));
  }

  @override
  Future<int> addSession({
    required String bookId,
    required int startedAtMillis,
    required int endedAtMillis,
  }) async {
    final doc = _booksCol.doc(bookId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      final current = (snap.data()?['totalReadSeconds'] as num?)?.toInt() ?? 0;
      final add = ((endedAtMillis - startedAtMillis) ~/ 1000).clamp(0, 1 << 31);
      final next = current + add;
      tx.set(doc, {'totalReadSeconds': next, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
      return next;
    });
  }
}
