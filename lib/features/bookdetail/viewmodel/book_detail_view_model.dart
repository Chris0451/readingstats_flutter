import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../shelves/model/reading_status.dart';
import '../../shelves/model/user_book.dart';

// FIREBASE
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookDetailViewModel extends ChangeNotifier {
  // Stato osservabile (mock + sync con Firestore)
  ReadingStatus? _status;
  int? _savedReadPages;
  int? _savedTotalPages;

  bool _isBusy = false;
  bool get isBusy => _isBusy;
  void _setBusy(bool v) { _isBusy = v; notifyListeners(); }

  ReadingStatus? get status => _status;
  int? get savedReadPages => _savedReadPages;
  int? get savedTotalPages => _savedTotalPages;

  final _events = StreamController<String>.broadcast();
  Stream<String> get events => _events.stream;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Utente non autenticato');
    return u.uid;
  }

  DocumentReference<Map<String, dynamic>> _ref(String volumeId) =>
      _db.collection('users').doc(_uid).collection('books').doc(volumeId);

  String? _volumeId;
  StreamSubscription? _sub;

  void bindVolume(String volumeId) {
    _volumeId = volumeId;
    _sub?.cancel();
    _sub = _ref(volumeId).snapshots().listen((snap) {
      if (!snap.exists) {
        _status = null;
        _savedReadPages = null;
        _savedTotalPages = null;
      } else {
        final d = snap.data()!;
        _status = _fromCode(d['status'] as String?);
        _savedReadPages = (d['pagesRead'] as num?)?.toInt();
        _savedTotalPages = (d['pageCount'] as num?)?.toInt();
      }
      notifyListeners();
    });
  }

  String _label(ReadingStatus s) => switch (s) {
    ReadingStatus.toRead => 'Da leggere',
    ReadingStatus.reading => 'In lettura',
    ReadingStatus.read    => 'Letto',
  };

  String _code(ReadingStatus s) => switch (s) {
    ReadingStatus.toRead => 'TO_READ',
    ReadingStatus.reading => 'READING',
    ReadingStatus.read    => 'READ',
  };
  ReadingStatus? _fromCode(String? s) => switch (s) {
    'TO_READ' => ReadingStatus.toRead,
    'READING' => ReadingStatus.reading,
    'READ'    => ReadingStatus.read,
    _         => null,
  };

  /// Scrittura atomica stato + pagine
  Future<void> setStatusWithPages({
    required ReadingStatus status,
    required UserBook userBook,
    UserBook? payload,
    int? pagesRead,
    int? totalPages,
  }) async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final prev = _status; // <<< stato prima del cambio
      final id = _volumeId ?? userBook.volumeId;
      final now = FieldValue.serverTimestamp();
      final data = <String, dynamic>{
        'id': userBook.id,
        'volumeId': userBook.volumeId,
        'title': userBook.title,
        'authors': userBook.authors,
        'thumbnail': userBook.thumbnail,
        'description': userBook.description,
        'isbn13': userBook.isbn13,
        'isbn10': userBook.isbn10,
        'status': _code(status),
        if (totalPages != null) 'pageCount': totalPages,
        if (pagesRead  != null) 'pagesRead': pagesRead,
        'updatedAt': now,
        'createdAt': now,
      };
      await _ref(id).set(data, SetOptions(merge: true));

      _status = status;
      _savedReadPages = pagesRead ?? _savedReadPages;
      _savedTotalPages = totalPages ?? _savedTotalPages ?? userBook.pageCount;

      final msg = (prev == null)
        ? 'Libro aggiunto alla lista ${_label(status)}'
        : 'Libro spostato da ${_label(prev)} a ${_label(status)}';
      _events.add(msg);

      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  /// Toggle: se riclicchi lo stesso stato, rimuove il libro dalla lista
  Future<void> onStatusIconClick(ReadingStatus clicked, UserBook? payload) async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final prev = _status;
      if (prev == clicked) {
        final id = _volumeId ?? payload?.volumeId;
        if (id != null) {
          await _ref(id).delete();
        }
        _status = null;
        _savedReadPages = null;
        _savedTotalPages = null;
        _events.add('Libro rimosso dalla lista ${_label(clicked)}');
      } else {
        // Se vuoi lasciare solo toggling, lascia così; 
        // i flussi con dialoghi sono gestiti dalla UI prima di chiamare setStatusWithPages.
        _status = clicked;
        _events.add(
          prev == null
              ? 'Libro aggiunto alla lista ${_label(clicked)}'
              : 'Stato cambiato da ${_label(prev)} a ${_label(clicked)}',
        );
      }
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> clearStatus() async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final id = _volumeId;
      final prev = _status;
      _status = null;
      _savedReadPages = null;
      if (id != null) {
          await _ref(id).delete();
      }
      // _savedTotalPages lo lasciamo com'è: può servire per futuri settaggi
      if (prev != null) {
        _events.add('Libro rimosso dalla lista ${_label(prev)}');
      }
      notifyListeners(); // <<< importante
    } finally {
      _setBusy(false);
    }
  }

  Future<void> toggleShelf({
    required String uid,
    required String bookId,
    required String shelfValue, // "TO_READ" | "READING" | "READ"
    required bool isCurrentlySelected,
  }) async {
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('books')
        .doc(bookId);

    if (isCurrentlySelected) {
      // RIMOZIONE dallo scaffale: elimino il campo 'status'
      await doc.update({
        'status': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // AGGIUNTA allo scaffale
      await doc.set({
        'status': shelfValue,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> updatePageCount(int pageCount) async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final id = _volumeId;
      if (id != null) {
        await _ref(id).set({'pageCount': pageCount, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      _savedTotalPages = pageCount;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updatePagesRead(int pages) async {
    if (_isBusy) return;
    _setBusy(true);
    try {
      final id = _volumeId;
      if (id != null) {
        await _ref(id).set({'pagesRead': pages, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }
      _savedReadPages = pages;
    } finally {
      _setBusy(false);
    }
  }

  @override
  void dispose() {
    _events.close();
    _sub?.cancel();
    super.dispose();
  }
}
