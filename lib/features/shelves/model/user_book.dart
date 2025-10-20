import '../../catalog/model/book.dart';
import 'reading_status.dart';

const _unset = Object();

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
    Object? pageInReading = _unset,
    Object? status = _unset,
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
      pageInReading: pageInReading == _unset ? this.pageInReading : pageInReading as int?,
      status: status == _unset ? this.status : status as ReadingStatus?,
    );
  }

  // in user_book.dart
  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      volumeId: json['volumeId'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String?,
      authors: (json['authors'] as List<dynamic>? ?? const []).cast<String>(),
      categories: (json['categories'] as List<dynamic>? ?? const []).cast<String>(),
      pageCount: json['pageCount'] as int?,
      description: json['description'] as String?,
      isbn13: json['isbn13'] as String?,
      isbn10: json['isbn10'] as String?,
      pageInReading: json['pageInReading'] as int?,
      status: parseReadingStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'volumeId': volumeId,
      'title': title,
      'thumbnail': thumbnail,
      'authors': authors,
      'categories': categories,
      'pageCount': pageCount,
      'description': description,
      'isbn13': isbn13,
      'isbn10': isbn10,
      'pageInReading': pageInReading,
      'status': status?.name, // se null non lo salvo
    };
    map.removeWhere((k, v) => v == null);
    return map;
  }
}
