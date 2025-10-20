import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shelves/model/reading_status.dart';
import 'dart:async';

extension ReadingStatusX on ReadingStatus {
  String get label {
    switch (this) {
      case ReadingStatus.toRead: return 'Da leggere';
      case ReadingStatus.reading: return 'In lettura';
      case ReadingStatus.read:   return 'Letti';
    }
  }
  IconData get icon {
    switch (this) {
      case ReadingStatus.toRead: return Icons.bookmark_add_outlined;
      case ReadingStatus.reading: return Icons.menu_book_outlined;
      case ReadingStatus.read:    return Icons.check_circle_outline;
    }
  }
  String get code => switch (this) {
    ReadingStatus.toRead => 'TO_READ',
    ReadingStatus.reading => 'READING',
    ReadingStatus.read    => 'READ',
  };
  static ReadingStatus? fromCode(String? s) => switch (s) {
    'TO_READ' => ReadingStatus.toRead,
    'READING' => ReadingStatus.reading,
    'READ'    => ReadingStatus.read,
    _         => null,
  };
}

/// Modello UI per riga scaffale
class UiShelfBook {
  final String id;
  final String title;
  final List<String> authors;
  final String? thumbnail;
  final int? pageCount;
  final String? description;
  final String? publishedDate;
  final String? isbn13;
  final String? isbn10;
  final int? pagesRead;
  const UiShelfBook({
    required this.id,
    required this.title,
    required this.authors,
    this.thumbnail,
    this.pageCount,
    this.pagesRead,
    this.description,
    this.publishedDate,
    this.isbn13,
    this.isbn10,
  });
}

class ShelvesViewModel extends ChangeNotifier {
  ShelvesViewModel._() { _attach(); }
  static final ShelvesViewModel instance = ShelvesViewModel._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final Map<ReadingStatus, List<UiShelfBook>> _booksByStatus = {
    ReadingStatus.toRead: <UiShelfBook>[],
    ReadingStatus.reading: <UiShelfBook>[],
    ReadingStatus.read: <UiShelfBook>[],
  };

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void _attach() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _sub?.cancel();
    _sub = _db
      .collection('users').doc(uid)
      .collection('books')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .listen((qs) {
        final tmp = {
          ReadingStatus.toRead: <UiShelfBook>[],
          ReadingStatus.reading: <UiShelfBook>[],
          ReadingStatus.read: <UiShelfBook>[],
        };
        for (final d in qs.docs) {
          final m = d.data();
          final st = ReadingStatusX.fromCode(m['status'] as String?);
          if (st == null) continue; // Il libro NON è in nessuno scaffale (status rimosso): non va mostrato.
          tmp[st]!.add(UiShelfBook(
            id: (m['id'] ?? d.id) as String,
            title: m['title'] as String? ?? '',
            authors: (m['authors'] is List) ? List<String>.from(m['authors'] as List) : const [],
            thumbnail: m['thumbnail'] as String?,
            description: m['description'] as String?,
            pageCount: (m['pageCount'] as num?)?.toInt(),
            pagesRead: (m['pagesRead'] as num?)?.toInt(),
          ));
        }
        _booksByStatus[ReadingStatus.toRead] = tmp[ReadingStatus.toRead]!;
        _booksByStatus[ReadingStatus.reading] = tmp[ReadingStatus.reading]!;
        _booksByStatus[ReadingStatus.read] = tmp[ReadingStatus.read]!;
        notifyListeners();
      });
  }

  List<ReadingStatus> get shelvesOrder => ReadingStatus.values;
  List<UiShelfBook> booksFor(ReadingStatus status) =>
      List<UiShelfBook>.unmodifiable(_booksByStatus[status] ?? const []);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}


