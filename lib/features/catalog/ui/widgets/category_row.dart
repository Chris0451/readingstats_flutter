import 'package:flutter/material.dart';
import '../../model/book.dart';
import 'book_card.dart';

class CategoryRow extends StatelessWidget {
  final String title;
  final List<Book> books;
  final ValueChanged<Book> onBookTap;

  const CategoryRow({
    super.key,
    required this.title,
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          if (books.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    for (final b in books)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BookCard(book: b, onTap: onBookTap),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
