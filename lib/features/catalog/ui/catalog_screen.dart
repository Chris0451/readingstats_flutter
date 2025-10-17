import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/book.dart';
import '../viewmodel/catalog_view_model.dart';
import 'widgets/book_card.dart';
import 'widgets/category_row.dart';
import '/core/ui/widgets/app_search_bar.dart';

class CatalogScreen extends StatelessWidget {
  final void Function(Book book)? onOpenBook;

  const CatalogScreen({super.key, this.onOpenBook});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => makeCatalogVm(),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatalogViewModel>();
    final s = vm.state;

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
      children: [
        // ---- SEARCH BAR ----
          AppSearchBar(
            text: s.query,
            hintText: 'Cerca titolo...',
            onChanged: vm.performLiveSearch,
            onSubmitted: (_) => vm.performSearch(),
            onClear: vm.clearSearch,
          ),

          // ---- FILTER BAR ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.selectedCategories.isEmpty
                      ? 'Tutte le categorie'
                      : 'Selezionate ${s.selectedCategories.length} categorie',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton(
                  onPressed: vm.openFilters,
                  child: const Text('Filtri'),
                )
              ],
            ),
          ),

          if (s.showFilters)
            _FiltersDialog(
              all: s.allCategories,
              selected: s.selectedCategories,
              onToggle: vm.toggleCategory,
              onClear: vm.clearFilters,
              onConfirm: vm.confirmFilters,
              onDismiss: vm.closeFilters,
            ),

          // ---- CONTENT ----
          Expanded(
            child: Builder(
              builder: (_) {
                if (s.searching) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.searchResult.isNotEmpty) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.48, // cover + title
                    ),
                    itemCount: s.searchResult.length,
                    itemBuilder: (context, i) {
                      final b = s.searchResult[i];
                      return BookCard(
                        book: b,
                        onTap: (bk) {
                          final cb = (context.findAncestorWidgetOfExactType<CatalogScreen>() as CatalogScreen?)?.onOpenBook;
                          if (cb != null) cb(bk);
                        },
                      );
                    },
                  );
                }
                // categorie
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: s.categories.length,
                  itemBuilder: (context, i) {
                    final row = s.categories[i];
                    return CategoryRow(
                      title: row.category,
                      books: row.books,
                      onBookTap: (bk) {
                        final cb = (context.findAncestorWidgetOfExactType<CatalogScreen>() as CatalogScreen?)?.onOpenBook;
                        if (cb != null) cb(bk);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersDialog extends StatelessWidget {
  final List<String> all;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const _FiltersDialog({
    required this.all,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 560, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Filtra per categoria', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: Scrollbar(
                  child: ListView.separated(
                    itemCount: all.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 2),
                    itemBuilder: (_, i) {
                      final c = all[i];
                      return CheckboxListTile(
                        value: selected.contains(c),
                        onChanged: (_) => onToggle(c),
                        title: Text(c),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onClear, child: const Text('Pulisci')),
                  TextButton(onPressed: onDismiss, child: const Text('Annulla')),
                  FilledButton(onPressed: onConfirm, child: const Text('Conferma')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
