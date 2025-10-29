import 'package:flutter/material.dart';
import '../viewmodel/shelves_view_model.dart';
import 'package:provider/provider.dart';
import '../../shelves/model/reading_status.dart';
import '../../bookdetail/ui/book_detail_screen.dart';
import '../../bookdetail/viewmodel/book_detail_view_model.dart';
import '../../catalog/model/book.dart';

class SelectedShelfArgs {
  final ReadingStatus status;
  const SelectedShelfArgs({required this.status});
}

class SelectedShelfScreen extends StatelessWidget {
  static const routeName = '/shelves/selected';
  const SelectedShelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as SelectedShelfArgs?;
    final status = args?.status ?? ReadingStatus.toRead;

    final vm = ShelvesViewModel.instance;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(status.label),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (context, _) {
          final books = vm.booksFor(status);

          if (books.isEmpty) {
            return _EmptyState(status: status);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final b = books[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: (status == ReadingStatus.reading && b.pageCount != null && b.pageInReading != null)
                    ? Text('${b.pageInReading} / ${b.pageCount} pagine')
                    : (b.authors.isNotEmpty
                        ? Text(b.authors.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null),
                trailing: (b.thumbnail != null && b.thumbnail!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(b.thumbnail!, width: 44, height: 64, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image_not_supported_outlined),
                onTap: () {
                  final book = Book(
                    id: b.id,
                    title: b.title,
                    authors: b.authors,
                    thumbnail: b.thumbnail,
                    pageCount: b.pageCount,
                    description: b.description,
                    isbn13: b.isbn13,
                    isbn10: b.isbn10,
                    publishedDate: b.publishedDate,
                  );
                  Navigator.of(context).push(
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
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ReadingStatus status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 56, color: outline),
            const SizedBox(height: 12),
            Text('Nessun libro in "${status.label}"', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Puoi aggiungerli dal Catalogo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: onVar),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
