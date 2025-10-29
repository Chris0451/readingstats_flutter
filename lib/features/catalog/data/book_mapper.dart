import '../../catalog/model/book.dart';
import '../../catalog/model/volume.dart';
import '../../catalog/model/volume.dart';

String? _asString(dynamic v) =>
    v == null ? null : (v is String ? v : v.toString());
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e == null ? '' : e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
String? _pickThumb(dynamic imageLinks) {
  if (imageLinks == null) return null;
  String? t;
  try {
    t = _asString(imageLinks.thumbnail) ?? _asString(imageLinks.smallThumbnail)
      ?? _asString(imageLinks.medium) ?? _asString(imageLinks.small);
  } catch (_) {
    if (imageLinks is Map) {
      t = _asString(imageLinks['thumbnail']) ?? _asString(imageLinks['smallThumbnail'])
        ?? _asString(imageLinks['medium']) ?? _asString(imageLinks['small']);
    }
  }
  if (t == null) return null;
  return t.startsWith('http://') ? t.replaceFirst('http://', 'https://') : t;
}

Map<String, String?> _extractIsbns(dynamic identifiers) {
  String? i13, i10;
  if (identifiers is List) {
    for (final it in identifiers) {
      String? type, id;
      if (it is Map) {
        type = _asString(it['type'])?.toUpperCase();
        id   = _asString(it['identifier'])?.replaceAll('-', '');
      } else {
        try {
          type = _asString(it.type)?.toUpperCase();
          id   = _asString(it.identifier)?.replaceAll('-', '');
        } catch (_) {}
      }
      if (type == 'ISBN_13' && (id?.isNotEmpty ?? false)) i13 = id;
      if (type == 'ISBN_10' && (id?.isNotEmpty ?? false)) i10 = id!.toUpperCase();
    }
  }
  return <String, String?>{'isbn13': i13, 'isbn10': i10};
}

Book bookFromVolume(Volume v) {
  final vi = v.info;

  final title = [
    _asString(vi?.title),
  ].where((e) => e != null && e!.trim().isNotEmpty).join(': ');

  final authors     = _asStringList(vi?.authors);
  final categories  = _asStringList(vi?.categories);
  final desc        = _asString(vi?.description);
  final published   = _asString(vi?.publishedDate);
  final pageCount   = _asInt(vi?.pageCount);
  final thumb       = _pickThumb(vi?.imageLinks);
  final ids         = _extractIsbns(vi?.industryIdentifiers);

  return Book(
    id: v.id,
    title: title.isEmpty ? 'Senza titolo' : title,
    authors: authors,
    categories: categories,
    thumbnail: thumb,
    pageCount: pageCount,
    description: desc,
    isbn13: ids['isbn13'],
    isbn10: ids['isbn10'],
    publishedDate: published,
  );
}
