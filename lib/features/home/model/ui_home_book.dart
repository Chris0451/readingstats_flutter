import 'package:flutter/foundation.dart';
import 'package:readingstats_flutter/features/shelves/model/user_book.dart';

const _uiUnset = Object();

@immutable
class UiHomeBook extends UserBook {
  final int totalReadSeconds;

  const UiHomeBook({
    required super.id,
    required super.volumeId,
    required super.title,
    required super.authors,
    super.thumbnail,
    super.categories = const [],
    super.publishedDate,
    super.pageCount,
    super.description,
    super.isbn13,
    super.isbn10,
    super.pageInReading,
    super.status,
    this.totalReadSeconds = 0,
  });

  @override
  UiHomeBook copyWith({
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
    Object? status = _uiUnset,
    Object? pageInReading = _uiUnset,
  }) {
    return UiHomeBook(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      thumbnail: thumbnail ?? this.thumbnail,
      categories: categories ?? this.categories,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      status: status == _uiUnset ? this.status : status as String?,
      pageInReading: pageInReading == _uiUnset ? this.pageInReading : pageInReading as int?,
      totalReadSeconds: totalReadSeconds,
    );
  }

  UiHomeBook copyWithHome({
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
    Object? status = _uiUnset,
    Object? pageInReading = _uiUnset,
    int? totalReadSeconds,
  }) {
    return UiHomeBook(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      thumbnail: thumbnail ?? this.thumbnail,
      categories: categories ?? this.categories,
      publishedDate: publishedDate ?? this.publishedDate,
      pageCount: pageCount ?? this.pageCount,
      description: description ?? this.description,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      status: status == _uiUnset ? this.status : status as String?,
      pageInReading: pageInReading == _uiUnset ? this.pageInReading : pageInReading as int?,
      totalReadSeconds: totalReadSeconds ?? this.totalReadSeconds,
    );
  }

  factory UiHomeBook.fromUserBook(UserBook b, {int totalReadSeconds = 0}) {
    return UiHomeBook(
      id: b.id,
      volumeId: b.volumeId,
      title: b.title,
      authors: b.authors,
      thumbnail: b.thumbnail,
      categories: b.categories,
      publishedDate: b.publishedDate,
      pageCount: b.pageCount,
      description: b.description,
      isbn13: b.isbn13,
      isbn10: b.isbn10,
      status: b.status,
      pageInReading: b.pageInReading,
      totalReadSeconds: totalReadSeconds,
    );
  }

  factory UiHomeBook.fromJson(Map<String, dynamic> json) {
    final base = UserBook.fromJson(json);
    return UiHomeBook(
      id: base.id,
      volumeId: base.volumeId,
      title: base.title,
      authors: base.authors,
      thumbnail: base.thumbnail,
      categories: base.categories,
      publishedDate: base.publishedDate,
      pageCount: base.pageCount,
      description: base.description,
      isbn13: base.isbn13,
      isbn10: base.isbn10,
      status: base.status,
      pageInReading: base.pageInReading,
      totalReadSeconds: (json['totalReadSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map['totalReadSeconds'] = totalReadSeconds;
    return map;
  }
}
