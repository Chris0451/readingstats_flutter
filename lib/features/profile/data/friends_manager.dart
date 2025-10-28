import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/friends_model.dart';

class FriendsManager {
  FriendsManager._();

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<List<Friend>> loadFriends() async {
    final current = _auth.currentUser;
    if (current == null) return [];
    final userDoc = await _db.collection('users').doc(current.uid).get();
    final uids = (userDoc.data()?['friends'] as List?)?.cast<String>() ?? const [];
    if (uids.isEmpty) return [];
    final snaps = await Future.wait(uids.map((uid) => _db.collection('users').doc(uid).get()));
    return snaps.where((s) => s.exists).map((s) => Friend.fromDoc(s)).toList();
  }

  static Future<List<Friend>> loadAllUsersExcludingCurrent() async {
    final current = _auth.currentUser;
    if (current == null) return [];
    final snap = await _db.collection('users').get();
    return snap.docs.where((d) => d.id != current.uid).map((d) => Friend.fromDoc(d)).toList();
  }

  static Future<Friend?> loadUserById(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return Friend.fromDoc(snap);
  }

  static Future<(Friend?, List<FriendBook>?)> loadUserWithBooksIfFriend(String uid) async {
    final current = _auth.currentUser;
    if (current == null) return (null, null);

    final meDoc = await _db.collection('users').doc(current.uid).get();
    final myFriends = (meDoc.data()?['friends'] as List?)?.cast<String>() ?? const [];

    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return (null, null);
    final friend = Friend.fromDoc(userDoc);

    if (!myFriends.contains(uid)) return (friend, null);

    final booksSnap = await _db.collection('users').doc(uid).collection('books').get();
    final books = booksSnap.docs.map((d) => FriendBook.fromDoc(d)).toList();
    return (friend, books);
  }

  static Future<(bool ok, String? error)> sendFriendRequest(String toUid) async {
    final current = _auth.currentUser;
    if (current == null) return (false, 'non autenticato');
    if (toUid.isEmpty || toUid.length <= 10 || toUid.contains('/')) return (false, 'uid non valido');

    try {
      await _db.collection('friend_requests').add({
        'fromUid': current.uid,
        'toUid': toUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'message': '',
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  static Future<List<FriendRequest>> loadReceivedRequests() async {
    final current = _auth.currentUser;
    if (current == null) return [];
    final snap = await _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: current.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.map((d) => FriendRequest.fromDoc(d)).toList();
  }

  static Future<List<String>> loadSentRequests() async {
    final current = _auth.currentUser;
    if (current == null) return [];
    final snap = await _db
        .collection('friend_requests')
        .where('fromUid', isEqualTo: current.uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((d) => (d.data()['toUid'] as String? ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static Future<(bool ok, String? error)> acceptFriendRequest(FriendRequest req) async {
    final me = _auth.currentUser;
    if (me == null) return (false, 'non autenticato');
    if (req.toUid != me.uid) return (false, 'non sei il destinatario');

    try {
      final batch = _db.batch();
      final reqRef = _db.collection('friend_requests').doc(req.id);
      batch.update(reqRef, {'status': 'accepted'});

      final myRef = _db.collection('users').doc(me.uid);
      batch.set(myRef, {
        'friends': FieldValue.arrayUnion([req.fromUid]),
      }, SetOptions(merge: true));

      await batch.commit();
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }


  static Future<(bool ok, String? error)> rejectFriendRequest(FriendRequest req) async {
    final me = _auth.currentUser;
    if (me == null) return (false, 'non autenticato');
    try {
      final ref = _db.collection('friend_requests').doc(req.id);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw StateError('not-found');
        final d = snap.data() as Map<String, dynamic>;
        if (d['toUid'] != me.uid) throw StateError('not-allowed');
        if (d['status'] == 'rejected') return;
        if (d['status'] != 'pending') throw StateError('invalid-status');
        tx.set(ref, {...d, 'status': 'rejected'});
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }


  // lib/features/profile/data/friends_manager.dart
  static Future<void> syncMyFriendsFromAcceptedRequests() async {
    final me = _auth.currentUser;
    if (me == null) return;
    final snap = await _db.collection('friend_requests')
        .where('fromUid', isEqualTo: me.uid)
        .where('status', isEqualTo: 'accepted')
        .get();
    final ids = snap.docs
        .map((d) => (d.data()['toUid'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    await _db.collection('users').doc(me.uid).set({
      'friends': FieldValue.arrayUnion(ids),
    }, SetOptions(merge: true));
  }


  static UserRelationshipStatus relationshipStatus(
    Friend user,
    List<Friend> friends,
    List<String> sent,
  ) {
    if (friends.any((f) => f.uid == user.uid)) return UserRelationshipStatus.isFriend;
    if (sent.contains(user.uid)) return UserRelationshipStatus.pending;
    return UserRelationshipStatus.notFriend;
  }

  static Future<(bool ok, String? error)> removeFriend(String friendUid) async {
    final me = _auth.currentUser;
    if (me == null) return (false, 'non autenticato');
    try {
      await _db.collection('users').doc(me.uid).update({
        'friends': FieldValue.arrayRemove([friendUid]),
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  static Future<(bool, String?)> _addFriendsReciprocally(String uid1, String uid2) async {
    try {
      await _db.collection('users').doc(uid1).set({
        'friends': FieldValue.arrayUnion([uid2]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(uid2).set({
        'friends': FieldValue.arrayUnion([uid1]),
      }, SetOptions(merge: true));
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }
}
