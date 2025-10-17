import 'package:flutter/foundation.dart';
import 'book.dart';

@immutable
class CategorySection {
  final String category;
  final List<Book> books;

  const CategorySection({required this.category, required this.books});

  CategorySection copyWith({String? category, List<Book>? books}) =>
      CategorySection(category: category ?? this.category, books: books ?? this.books);
}