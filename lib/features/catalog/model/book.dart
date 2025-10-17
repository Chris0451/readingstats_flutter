import 'package:flutter/foundation.dart';

@immutable
class Book {
  final String id;
  final String title;
  final String? thumbnail;
  final List<String> authors;

  const Book({
    required this.id,
    required this.title,
    this.thumbnail,
    this.authors = const [],
  });
}
