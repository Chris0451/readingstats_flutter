import 'package:flutter/foundation.dart';
import 'book.dart';
import 'category_section.dart';

@immutable
class CatalogState {
  final String query;
  final bool searching;

  final List<Book> searchResult;

  final List<String> allCategories;
  final Set<String> selectedCategories;
  final bool showFilters;

  final List<CategorySection> categories;

  const CatalogState({
    this.query = '',
    this.searching = false,
    this.searchResult = const [],
    this.allCategories = const [],
    this.selectedCategories = const {},
    this.showFilters = false,
    this.categories = const [],
  });

  CatalogState copyWith({
    String? query,
    bool? searching,
    List<Book>? searchResult,
    List<String>? allCategories,
    Set<String>? selectedCategories,
    bool? showFilters,
    List<CategorySection>? categories,
  }) {
    return CatalogState(
      query: query ?? this.query,
      searching: searching ?? this.searching,
      searchResult: searchResult ?? this.searchResult,
      allCategories: allCategories ?? this.allCategories,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      showFilters: showFilters ?? this.showFilters,
      categories: categories ?? this.categories,
    );
  }
}
