import '../model/volume.dart';
import 'books_api.dart';

class BooksRepository {
  final BooksApi api;
  BooksRepository(this.api);

  Future<(List<Volume> items, int total)> search({
    required String query,
    int startIndex = 0,
    int pageSize = 20,
    String orderBy = 'relevance',
    String printType = 'books',
    String lang = 'it',
  }) async {
    final res = await api.search(
      q: query,
      startIndex: startIndex,
      maxResults: pageSize,
      orderBy: orderBy,
      printType: printType,
      langRestrict: lang,
    );
    return (res.items ?? const [], res.totalItems ?? 0);
    }

  Future<Volume> get(String id) => api.getById(id);
}
