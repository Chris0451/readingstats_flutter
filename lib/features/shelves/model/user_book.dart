import '../../catalog/model/book.dart';
import 'reading_status.dart';

class UserBook {
  final String id;             // = volumeId
  final String volumeId;
  final String title;
  final String? thumbnail;
  final List<String> authors;
  final List<String> categories;
  final int? pageCount;        // totale pagine (se noto)
  final String? description;
  final String? isbn13;
  final String? isbn10;

  final int? pageInReading;    // pagine lette
  final ReadingStatus? status;

  const UserBook({
    required this.id,
    required this.volumeId,
    required this.title,
    this.thumbnail,
    this.authors = const [],
    this.categories = const [],
    this.pageCount,
    this.description,
    this.isbn13,
    this.isbn10,
    this.pageInReading,
    this.status,
  });

  UserBook copyWith({
    String? id,
    String? volumeId,
    String? title,
    String? thumbnail,
    List<String>? authors,
    List<String>? categories,
    int? pageCount,
    String? description,
    String? isbn13,
    String? isbn10,
    int? pageInReading,
    ReadingStatus? status,
  }) {
    return UserBook(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      authors: authors ?? this.authors,
      categories: categories ?? this.categories,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      pageInReading: pageInReading ?? this.pageInReading,
      status: status ?? this.status,
    );
  }
}
