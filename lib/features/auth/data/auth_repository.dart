import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  Stream<User?> authState() => _auth.authStateChanges();

  // Controllo disponibilità usando la collezione "usernames"
  Future<bool> isUsernameAvailable(String username) async {
    final u = username.trim().toLowerCase();
    if (u.isEmpty) return false;
    final doc = await _db.collection('usernames').doc(u).get();
    return !doc.exists;
  }

  // Registrazione con prenotazione atomica dell'username
  Future<void> register({
  required String name,
  required String surname,
  required String username,
  required String email,
  required String password,
  }) async {
    final uLower = username.trim().toLowerCase();
    final unameRef = _db.collection('usernames').doc(uLower);

    // 1) Prenota l'username (no auth necessaria, crea solo createdAt)
    await _db.runTransaction((tx) async {
      final snap = await tx.get(unameRef);
      if (snap.exists) {
        throw FirebaseAuthException(code: 'username-taken', message: 'Username non disponibile');
      }
      tx.set(unameRef, {'createdAt': FieldValue.serverTimestamp()});
    });

    try {
      // 2) Crea account su Firebase Auth
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await cred.user?.updateDisplayName('${name.trim()} ${surname.trim()}');

      // 3) Scrivi profilo utente + collega l'username con il tuo uid
      final uid = cred.user!.uid;
      final userRef = _db.collection('users').doc(uid);

      final batch = _db.batch();
      batch.set(userRef, {
        'uid': uid,
        'name': name.trim(),
        'surname': surname.trim(),
        'username': username.trim(),
        'usernameLower': uLower,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ora puoi aggiornare il doc username con il tuo uid (sei autenticato)
      batch.update(unameRef, {'uid': uid});

      await batch.commit();
    } on FirebaseAuthException {
      // rollback soft: la delete potrebbe non essere consentita dalle regole
      await unameRef.delete().catchError((_) {});
      rethrow;
    } on FirebaseException catch (e) {
      // non provare a cancellare il doc: le regole vietano delete
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (_) {
      throw FirebaseAuthException(code: 'unknown', message: 'Registrazione fallita');
    }
  }

  Future<void> login({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> logout() => _auth.signOut();
}
