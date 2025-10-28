import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  ProfileRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromDoc(snap);
  }

  Future<void> updateUserProfile({
    required String username,
    required String name,
    required String surname,
    required String email,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Nessun utente autenticato.');
    }

    final userRef = _db.collection('users').doc(uid);
    final newLower = username.trim().toLowerCase();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final data = (userSnap.data() as Map<String, dynamic>?) ?? {};
      final oldLower = (data['usernameLower'] as String?)?.trim().toLowerCase() ?? '';

      void updateUserDoc() {
        tx.set(
          userRef,
          {
            'uid': uid,
            'username': username.trim(),
            'usernameLower': newLower,
            'name': name.trim(),
            'surname': surname.trim(),
            'email': email.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (newLower == oldLower) {
        updateUserDoc();
        return;
      }

      final newURef = _db.collection('usernames').doc(newLower);
      final newUSnap = await tx.get(newURef);
      if (newUSnap.exists) {
        final owner = (newUSnap.data()?['uid'] as String?);
        if (owner != null && owner != uid) {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'username-taken', message: 'Username non disponibile');
        }
        if (owner == null) {
          tx.set(newURef, {
            'createdAt': newUSnap.data()?['createdAt'],
            'uid': uid,
          });
        }
      } else {
        tx.set(newURef, {'createdAt': FieldValue.serverTimestamp()});
      }

      updateUserDoc();

      if (oldLower.isNotEmpty) {
        final oldURef = _db.collection('usernames').doc(oldLower);
        final oldSnap = await tx.get(oldURef);
        final oldOwner = oldSnap.data()?['uid'] as String?;
        if (oldOwner == uid) {
          tx.delete(oldURef);
        }
      }
    });

    final docRef = _db.collection('usernames').doc(newLower);
    final s = await docRef.get();
    final owner = s.data()?['uid'] as String?;
    if (owner == null) {
      final createdAt = s.data()?['createdAt'];
      await docRef.set({'createdAt': createdAt, 'uid': uid});
    }
  }
}
