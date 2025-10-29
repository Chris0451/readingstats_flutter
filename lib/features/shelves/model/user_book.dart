import 'package:flutter/foundation.dart';
import 'package:readingstats_flutter/features/catalog/model/book.dart';

const _unset = Object();

@immutable
class UserBook extends Book {
  final String volumeId;
  final String? status;
  final int? pageInReading;

  const UserBook({
    required super.id,
    required super.title,
    required super.authors,
    super.thumbnail,
    super.categories = const [],
    super.publishedDate,
    super.pageCount,
    super.description,
    super.isbn13,
    super.isbn10,
    String? volumeId,
    this.status,
    this.pageInReading,
  }) : volumeId = volumeId ?? id;

  UserBook copyWith({
    String? id,
    String? title,
    List<String>? authors,
    String? thumbnail,
    List<String>? categories,
    String? publishedDate,
    int? pageCount,
    String? description,
    String? isbn13,
    String? isbn10,
    String? volumeId,
    Object? status = _unset,
    Object? pageInReading = _unset,
  }) {
    return UserBook(
      id: id ?? this.id,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      thumbnail: thumbnail ?? this.thumbnail,
      categories: categories ?? this.categories,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      volumeId: volumeId ?? this.volumeId,
      status: status == _unset ? this.status : status as String?,
      pageInReading: pageInReading == _unset ? this.pageInReading : pageInReading as int?,
    );
  }

  // ---------------- JSON / Firestore ----------------

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      // Book
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      authors: (json['authors'] as List<dynamic>? ?? const []).cast<String>(),
      thumbnail: json['thumbnail'] as String?,
      categories: (json['categories'] as List<dynamic>? ?? const []).cast<String>(),
      publishedDate: json['publishedDate'] as String?,
      pageCount: (json['pageCount'] as num?)?.toInt(),
      description: json['description'] as String?,
      isbn13: json['isbn13'] as String?,
      isbn10: json['isbn10'] as String?,
      // UserBook extra
      volumeId: (json['volumeId'] as String?) ?? (json['id'] as String),
      status: json['status'] as String?,
      pageInReading: (json['pageInReading'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      // Book
      'id': id,
      'title': title,
      'thumbnail': thumbnail,
      'authors': authors,
      'categories': categories,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'description': description,
      'isbn13': isbn13,
      'isbn10': isbn10,
      'volumeId': volumeId,
      'status': status,
      'pageInReading': pageInReading,
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }
}
