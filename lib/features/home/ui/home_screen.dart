import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:readingstats_flutter/features/home/viewmodel/home_view_model.dart';
import 'package:readingstats_flutter/features/home/ui/widgets/pages_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final state = vm.uiState;

    if (state.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: const Center(child: Text('Nessun libro in lettura')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = state.items[i];
              return _ReadingCard(
                item: item,
                onStart: () => vm.onStart(item.book),
                onStop: () => vm.onStop(item.book),
              );
            },
          ),
          if (state.pagesDialog != null)
            PagesDialog(
              book: state.pagesDialog!.book,
              initial: state.pagesDialog!.currentRead,
              onDismiss: vm.closeDialog,
              onConfirm: (n) => vm.confirmPages(n),
            ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final HomeItemState item;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ReadingCard({
    required this.item,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final b = item.book;
    final total = b.pageCount ?? 0;
    final read = b.pageInReading ?? 0;
    final btnText = item.isRunning ? '⏹️ Termina lettura' : '▶️ Riprendi lettura';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 160,
                height: 220,
                child: _BookCover(url: b.thumbnail),
              ),
            ),
            const SizedBox(height: 12),
            // title
            Text(
              b.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // progress + time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ReadingProgressCircle(read: read, total: total, size: 56, stroke: 6),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total > 0 ? '$read pagine lette su $total' : '$read pagine lette',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Tempo totale: ${_formatSeconds(item.totalWithSession)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            // timer button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: item.isRunning ? onStop : onStart,
                child: Text(btnText),
              ),
            ),
            if (item.isRunning) ...[
              const SizedBox(height: 8),
              Text(
                'Sessione corrente: ${_formatSeconds(item.sessionElapsedSec)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadingProgressCircle extends StatelessWidget {
  final int read;
  final int total;
  final double size;
  final double stroke;

  const _ReadingProgressCircle({
    required this.read,
    required this.total,
    this.size = 56,
    this.stroke = 6,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (total > 0) ? (read / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: stroke,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.surfaceVariant,
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: stroke,
          ),
          Center(
            child: Text(
              total > 0 ? '${(progress * 100).round()}%' : '0%',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? url;
  const _BookCover({this.url});

  @override
  Widget build(BuildContext context) {
    final safe = (url == null || url!.isEmpty)
        ? null
        : url!.startsWith('http://')
            ? url!.replaceFirst('http://', 'https://')
            : url!;
    Widget ph() => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Icon(Icons.menu_book_outlined, size: 48),
        );
    if (safe == null) return ph();
    return Image.network(
      safe,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, p) =>
          p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) => ph(),
    );
  }
}

// utils
String _formatSeconds(int total) {
  final hh = total ~/ 3600;
  final mm = (total % 3600) ~/ 60;
  final ss = total % 60;
  return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
}
