import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:readingstats_flutter/features/home/model/ui_home_book.dart';
import 'package:readingstats_flutter/features/shelves/model/reading_status.dart';
import 'package:readingstats_flutter/features/shelves/model/user_book.dart';
import 'package:readingstats_flutter/features/home/data/home_repository.dart';

class HomeItemState{
  final UiHomeBook book;
  final bool isRunning;
  final int? sessionStartMillis;
  final int sessionElapsedSec;
  final int totalReadSec;

  const HomeItemState({
    required this.book,
    required this.isRunning,
    required this.sessionStartMillis,
    required this.sessionElapsedSec,
    required this.totalReadSec,
  });

  int get totalWithSession => totalReadSec + (isRunning ? sessionElapsedSec : 0);
}

class PagesDialogState {
  final UiHomeBook book;
  final int currentRead;
  const PagesDialogState({required this.book, required this.currentRead});
}

class HomeUiState {
  final List<HomeItemState> items;
  final PagesDialogState? pagesDialog;
  const HomeUiState({this.items = const [], this.pagesDialog});
}

class HomeViewModel extends ChangeNotifier {
  final HomeRepository repo;

  HomeViewModel(this.repo) {
    _booksSub = repo.observeReadingBooks().listen((books) {
      _books = books;
      _rebuild();
    },
    onError: (e, st){
      debugPrint('HomeVM observeReadingBooks error: $e');
    });
  }

  // stato interno
  final Map<String, int> _running = <String, int>{};  // bookId -> startMillis
  final Map<String, int> _ticking = <String, int>{};  // bookId -> elapsedSec
  Timer? _ticker;
  PagesDialogState? _dialog;
  List<UiHomeBook> _books = [];
  late final StreamSubscription _booksSub;

  HomeUiState _state = const HomeUiState();
  HomeUiState get uiState => _state;

  // API UI
  void onStart(UiHomeBook book) {
    if (_running.containsKey(book.id)) return;
    _running[book.id] = DateTime.now().millisecondsSinceEpoch;
    _startTickerIfNeeded();
    _rebuild();
  }

  void onStop(UiHomeBook book) {
    final start = _running.remove(book.id);
    if (start == null) return;

    final end = DateTime.now().millisecondsSinceEpoch;
    _ticking.remove(book.id);
    _stopTickerIfIdle();

    // mostra subito dialog
    _dialog = PagesDialogState(book: book, currentRead: book.pageInReading ?? 0);
    _rebuild();

    // salva sessione in background
    unawaited(repo.addSession(bookId: book.id, startedAtMillis: start, endedAtMillis: end));
  }

  void closeDialog() {
    _dialog = null;
    _rebuild();
  }

  Future<void> confirmPages(int pages) async {
    final dlg = _dialog;
    if (dlg == null) return;
    final total = dlg.book.pageCount ?? 0;

    await repo.updatePagesRead(dlg.book.id, pages);

    if (total > 0 && pages >= total) {
      final b = dlg.book;
      await repo.setStatus(
        bookId: b.id,
        status: code(ReadingStatus.read),
        payload: UserBook(
          id: b.id,
          volumeId: b.volumeId,
          title: b.title,
          thumbnail: b.thumbnail,
          authors: b.authors,
          categories: b.categories,
          pageCount: b.pageCount,
          description: b.description,
          isbn13: b.isbn13,
          isbn10: b.isbn10,
          pageInReading: pages,
          status: code(ReadingStatus.read),
        ),
      );
    }

    _dialog = null;
    _rebuild();
  }

  // ticker 1Hz per i timer attivi
  void _startTickerIfNeeded() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (_running.isEmpty) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      _ticking
        ..clear()
        ..addAll(
          _running.map(
            (id, start) => MapEntry(id, ((now - start) ~/ 1000)),
          ),
        );
      _rebuild();
    });
  }

  void _stopTickerIfIdle() {
    if (_running.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _rebuild() {
    final items = _books.map((b) {
      final isRun = _running.containsKey(b.id);
      return HomeItemState(
        book: b,
        isRunning: isRun,
        sessionStartMillis: _running[b.id],
        sessionElapsedSec: _ticking[b.id] ?? 0,
        totalReadSec: b.totalReadSeconds,
      );
    }).toList();

    _state = HomeUiState(items: items, pagesDialog: _dialog);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _booksSub.cancel();
    super.dispose();
  }
}
