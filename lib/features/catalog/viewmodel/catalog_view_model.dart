import 'dart:async';
import 'package:flutter/foundation.dart';

import '../model/book.dart';
import '../model/volume.dart';
import '../model/category_section.dart';
import '../model/catalog_state.dart';

import '../../catalog/data/books_repository.dart';
import '../../catalog/data/books_api.dart';

Book _mapVolumeToBook(Volume v) => Book(
  id: v.id,
  title: v.info.title ?? 'Senza titolo',
  authors: v.info.authors ?? const [],
  thumbnail: v.info.imageLinks?.thumbnail,
  categories: v.info.categories ?? const [],
  publishedDate: v.info.publishedDate,
  pageCount: v.info.pageCount,
  description: v.info.description,
  isbn13: v.info.isbn13,
  isbn10: v.info.isbn10,
);

const kBooksApiKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

class CatalogViewModel extends ChangeNotifier {
  final BooksRepository _repo;

  CatalogState _state = const CatalogState(
    allCategories: [
      "Fantasy",
      "Horror",
      "Romance",
      "Thrillers",
      "Science Fiction",
      "Adventure"
    ],
  );
  CatalogState get state => _state;

  Timer? _debounce;

  CatalogViewModel(this._repo) {
    _loadCategoryFeeds();
  }

  // ---- Search ----
  void updateQuery(String q) {
    _state = _state.copyWith(query: q);
    notifyListeners();
  }

  Future<void> performSearch() => _search(reset: true);

  Future<void> performLiveSearch(String q) async {
    updateQuery(q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(reset: true));
  }

  Future<void> _search({required bool reset}) async {
    final q = state.query.trim();
    if (q.isEmpty) {
      _state = _state.copyWith(searching: false, searchResult: const []);
      notifyListeners();
      return;
    }
    _state = _state.copyWith(searching: true);
    notifyListeners();
    try {
      final (items, _) = await _repo.search(query: q, startIndex: 0, pageSize: 30, orderBy: 'relevance');
      final books = items.map(_mapVolumeToBook).toList();
      _state = _state.copyWith(searchResult: books, searching: false);
    } catch (_) {
      _state = _state.copyWith(searching: false, searchResult: const []);
    }
    notifyListeners();
  }

  void clearSearch() {
    _state = _state.copyWith(query: '', searchResult: const []);
    notifyListeners();
  }

  // ---- Filters ----
  void openFilters() { _state = _state.copyWith(showFilters: true); notifyListeners(); }
  void closeFilters() { _state = _state.copyWith(showFilters: false); notifyListeners(); }

  void toggleCategory(String category) {
    final set = {..._state.selectedCategories};
    if (set.contains(category)) set.remove(category); else set.add(category);
    _state = _state.copyWith(selectedCategories: set);
    notifyListeners();
  }

  void clearFilters() {
    _state = _state.copyWith(selectedCategories: {});
    notifyListeners();
  }

  Future<void> confirmFilters() async {
    _state = _state.copyWith(showFilters: false);
    await _loadCategoryFeeds();
  }

  Future<void> _loadCategoryFeeds() async {
    final categoriesToLoad = _state.selectedCategories.isEmpty
        ? _state.allCategories
        : _state.selectedCategories.toList();

    List<CategorySection> sections = [];
    for (final c in categoriesToLoad) {
      try {
        final (items, _) = await _repo.search(query: 'subject:${c.replaceAll(' ', '+')}', startIndex: 0, pageSize: 10);
        final books = items.map(_mapVolumeToBook).toList();
        sections.add(CategorySection(category: c, books: books));
      } catch (_) {
        sections.add(const CategorySection(category: 'Errore', books: []));
      }
    }
    _state = _state.copyWith(categories: sections);
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

CatalogViewModel makeCatalogVm() {
  final repo = BooksRepository(BooksApi(apiKey: kBooksApiKey));
  return CatalogViewModel(repo);
}
