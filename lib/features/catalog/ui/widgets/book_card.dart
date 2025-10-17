import 'package:flutter/material.dart';
import '../../model/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final ValueChanged<Book> onTap;
  final int titleMaxLines;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.titleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(book),
      child: SizedBox(
        width: 120,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 110 / 170,
                  child: book.thumbnail != null && book.thumbnail!.isNotEmpty
                      ? Image.network(book.thumbnail!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.menu_book_outlined, size: 40),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Text(
                  book.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
