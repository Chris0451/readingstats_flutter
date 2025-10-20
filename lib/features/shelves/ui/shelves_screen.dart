import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../viewmodel/shelves_view_model.dart';
import 'selected_shelf_screen.dart';
import 'package:provider/provider.dart';
import '../../bookdetail/ui/book_detail_screen.dart';
import '../../bookdetail/viewmodel/book_detail_view_model.dart';
import '../../catalog/model/book.dart';
import '../../catalog/data/books_api.dart';
import 'widgets/isbn_scan_screen.dart';
import '../../catalog/data/book_mapper.dart';

class ShelvesScreen extends StatelessWidget {
  static const routeName = '/shelves';
  const ShelvesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = ShelvesViewModel.instance;
    final order = vm.shelvesOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei scaffali'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: order.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final status = order[index];
          return _ShelfTile(
            icon: status.icon,
            title: status.label,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SelectedShelfScreen(),
                  settings: RouteSettings(arguments: SelectedShelfArgs(status: status)),
                ),
              );
            },
          );
        },
      ),
      // FAB: scansiona ISBN e naviga al dettaglio
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scansiona ISBN'),
        onPressed: () async {
          final api = context.read<BooksApi>();
          final nav = Navigator.of(context);
          final msg = ScaffoldMessenger.of(context);
          void toast(String t) => msg.showSnackBar(SnackBar(content: Text(t)));

          final isbn = await nav.push<String?>(
            MaterialPageRoute(builder: (_) => const IsbnScanScreen()),
          );
          if (isbn == null) return;

          try {
            // 1) cerca per ISBN
            final res = await api.search(q: 'isbn:$isbn', maxResults: 1);
            final items = res.items ?? const [];
            if (items.isEmpty) {
              toast('Nessun libro trovato per ISBN $isbn');
              return;
            }

            // 2) prendi un id valido
            final id = items.first.id ?? items.first.info?.industryIdentifiers?.first.identifier;
            if (id == null || id.isEmpty) {
              toast('Risultato ISBN senza ID volume');
              return;
            }

            // 3) fetch completo + mapping unico
            final full = await api.getById(id);
            debugPrint('SCAN getById -> id=$id title=${full.info?.title}');
            final book = bookFromVolume(full); // <-- usa il mapper condiviso

            // 4) apri dettaglio
            await nav.push(
              MaterialPageRoute(
                builder: (routeCtx) => ChangeNotifierProvider(
                  create: (_) => BookDetailViewModel(),
                  child: BookDetailScreen(
                    book: book,
                    onBack: () => Navigator.of(routeCtx).maybePop(),
                  ),
                ),
              ),
            );
          } on DioException catch (e) {
            final code = e.response?.statusCode;
            final msg  = (e.response?.data is Map && e.response?.data['error'] is Map)
                ? e.response?.data['error']['message'] as String?
                : null;
            toast('[${code ?? '-'}] ${msg ?? e.message}');
          } catch (e, s) {
            debugPrint('SCAN FLOW ERROR: $e\n$s');
            toast('Errore durante la ricerca');
          }
        },
      ),
    );
  }
}

class _ShelfTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ShelfTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: onColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: onColor),
                ),
              ),
              Icon(Icons.chevron_right, color: onColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Helpers ----------
String? _asString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  return v.toString();
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v
        .map((e) => e == null ? '' : e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const [];
}

String? _thumbHttps(String? url) {
  if (url == null || url.isEmpty) return null;
  return url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
}

/// Estrae ISBN_13 / ISBN_10 da `industryIdentifiers` che può essere
/// List<Map> oppure una lista di oggetti tipizzati con .type/.identifier
Map<String, String?> _extractIsbns(dynamic identifiers) {
  String? i13;
  String? i10;

  if (identifiers is List) {
    for (final it in identifiers) {
      String? type;
      String? id;

      if (it is Map) {
        type = _asString(it['type'])?.toUpperCase();
        id   = _asString(it['identifier'])?.replaceAll('-', '');
      } else {
        // supporto a modelli tipizzati
        try {
          // ignore: avoid_dynamic_calls
          type = _asString(it.type)?.toUpperCase();
          // ignore: avoid_dynamic_calls
          id   = _asString(it.identifier)?.replaceAll('-', '');
        } catch (_) {}
      }

      if (type == 'ISBN_13' && (id?.isNotEmpty ?? false)) i13 = id;
      if (type == 'ISBN_10' && (id?.isNotEmpty ?? false)) i10 = id!.toUpperCase();
    }
  }

  return <String, String?>{'isbn13': i13, 'isbn10': i10};
}

// ---------- Mapper ----------
Book _mapVolumeToBook(dynamic vol) {
  // id
  String id = '';
  try {
    // ignore: avoid_dynamic_calls
    id = _asString(vol.id) ?? '';
  } catch (_) {
    if (vol is Map) id = _asString(vol['id']) ?? '';
  }

  // volumeInfo (può essere obj o Map)
  dynamic info;
  try {
    // ignore: avoid_dynamic_calls
    info = vol.volumeInfo;
  } catch (_) {
    if (vol is Map) info = vol['volumeInfo'];
  }

  if (info == null) {
    // fallback super-minimale
    return Book(
      id: id,
      title: '',
      authors: const [],
      categories: const [],
      thumbnail: null,
      pageCount: null,
      description: null,
      isbn13: null,
      isbn10: null,
      publishedDate: null,
    );
  }

  // campi base
  String? title;
  List<String> authors = const [];
  List<String> categories = const [];
  String? description;
  String? publishedDate;
  dynamic imageLinks;
  dynamic pageCountRaw;
  dynamic idsRaw;

  try {
    // ignore: avoid_dynamic_calls
    title         = _asString(info.title);
    // ignore: avoid_dynamic_calls
    authors       = _asStringList(info.authors);
    // ignore: avoid_dynamic_calls
    categories    = _asStringList(info.categories);
    // ignore: avoid_dynamic_calls
    description   = _asString(info.description);
    // ignore: avoid_dynamic_calls
    publishedDate = _asString(info.publishedDate);
    // ignore: avoid_dynamic_calls
    imageLinks    = info.imageLinks;     // obj o Map
    // ignore: avoid_dynamic_calls
    pageCountRaw  = info.pageCount;
    // ignore: avoid_dynamic_calls
    idsRaw        = info.industryIdentifiers;
  } catch (_) {
    if (info is Map) {
      title         = _asString(info['title']);
      authors       = _asStringList(info['authors']);
      categories    = _asStringList(info['categories']);
      description   = _asString(info['description']);
      publishedDate = _asString(info['publishedDate']);
      imageLinks    = info['imageLinks'];
      pageCountRaw  = info['pageCount'];
      idsRaw        = info['industryIdentifiers'];
    }
  }

  // thumbnail (obj o Map)
  String? thumb;
  try {
    // ignore: avoid_dynamic_calls
    thumb = _thumbHttps(_asString(imageLinks?.thumbnail));
  } catch (_) {
    if (imageLinks is Map) {
      thumb = _thumbHttps(_asString(imageLinks['thumbnail']));
    }
  }

  final pageCount = _asInt(pageCountRaw);
  final isbns     = _extractIsbns(idsRaw);

  return Book(
    id: id,
    title: title ?? '',
    authors: authors,
    categories: categories,
    thumbnail: thumb,
    pageCount: pageCount,
    description: description,
    isbn13: isbns['isbn13'],
    isbn10: isbns['isbn10'],
    publishedDate: publishedDate,
  );
}
