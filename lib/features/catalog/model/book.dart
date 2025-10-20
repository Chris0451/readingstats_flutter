import 'package:flutter/foundation.dart';

@immutable
class Book {
  final String id;
  final String title;
  final String? thumbnail;
  final List<String> authors;
  final List<String> categories;
  final String? publishedDate;
  final int? pageCount;
  final String? description;
  final String? isbn13;
  final String? isbn10;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    this.thumbnail,
    this.categories = const [],
    this.publishedDate,
    this.pageCount,
    this.description,
    this.isbn13,
    this.isbn10,
  });

  Book copyWith({
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
  }) {
    return Book(
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
    );
  }
}
