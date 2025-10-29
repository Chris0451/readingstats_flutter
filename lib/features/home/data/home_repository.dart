import 'package:readingstats_flutter/features/home/model/ui_home_book.dart';
import 'package:readingstats_flutter/features/shelves/model/user_book.dart';

abstract class HomeRepository {
  /// Stream dei libri con status == reading
  Stream<List<UiHomeBook>> observeReadingBooks();

  /// Aggiorna il totale delle pagine lette
  Future<void> updatePagesRead(String bookId, int pages);

  /// Cambia stato del libro con eventuale payload completo
  Future<void> setStatus({
    required String bookId,
    required String status,
    required UserBook payload,
  });

  /// Registra una sessione (start/end in millis) e incrementa totalReadSeconds
  Future<int> addSession({
    required String bookId,
    required int startedAtMillis,
    required int endedAtMillis,
  });
}