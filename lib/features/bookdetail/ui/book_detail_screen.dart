import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../catalog/model/book.dart';
import '../../shelves/model/reading_status.dart';
import '../../shelves/model/user_book.dart';
import '../viewmodel/book_detail_view_model.dart';
import 'widgets/reading_dialogs.dart';
import 'dart:async';

enum ReadingFlowMode { start, update }

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final VoidCallback onBack;

  const BookDetailScreen({super.key, required this.book, required this.onBack});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _busy = false;
  StreamSubscription<String>? _eventsSub;
  ReadingFlowMode? readingMode;
  UserBook? readingPayload;
  late final UserBook baseUserBook;

  ReadingStatus? totalOnlyFor;
  String totalOnlyValue = '';
  String? totalOnlyError;

  // Dialog semplice numerico
  Future<int?> _askPositiveInt({
    required String title,
    required String label,
    int min = 1,
    int? max,
    int? initial,
  }) async {
    final c = TextEditingController(text: (initial ?? '').toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            hintText: '>= $min${max != null ? " e <= $max" : ""}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annulla')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(c.text.trim());
              if (v == null || v < min || (max != null && v > max)) return;
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();

    baseUserBook = UserBook(
      id: widget.book.id,
      volumeId: widget.book.id,
      title: widget.book.title,
      thumbnail: widget.book.thumbnail,
      authors: widget.book.authors,
      categories: widget.book.categories,
      pageCount: widget.book.pageCount,
      description: widget.book.description,
      isbn13: widget.book.isbn13,
      isbn10: widget.book.isbn10,
      pageInReading: null,
      status: null,
    );
    // VM locale (mock/in-memory finché non colleghi il repository)
    // Puoi anche fornire il VM dall’alto con Provider se preferisci.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookDetailViewModel>().bindVolume(widget.book.id);
    });
    // Snack eventi
    _eventsSub = context.read<BookDetailViewModel>().events.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(msg)));
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookDetailViewModel>();
    final b = widget.book;

    final totalPages = context.select<BookDetailViewModel, int?>((vm) => vm.savedTotalPages) ?? b.pageCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
        title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 140/200,
                      child: _BookCover(url: b.thumbnail),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.title, style: Theme.of(context).textTheme.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (b.authors.isNotEmpty) Text(b.authors.join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (b.publishedDate != null) Text(b.publishedDate!, style: Theme.of(context).textTheme.bodySmall),
                      if (b.pageCount != null) Text('${b.pageCount} pagine', style: Theme.of(context).textTheme.bodySmall),
                      if (b.isbn13 != null) Text('isbn13: ${b.isbn13}', style: Theme.of(context).textTheme.bodySmall),
                      if (b.isbn10 != null) Text('isbn10: ${b.isbn10}', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      _BookStatusBar(
                        current: vm.status,
                        disabled: vm.isBusy || _busy, // ← disattiva subito i bottoni
                        onSet: (newStatus) async {
                          final payload = baseUserBook.copyWith(pageCount: totalPages);

                          setState(() => _busy = true);
                          try {
                            // Toggle OFF: riclic su stessa icona -> rimuovi 'status'
                            if (vm.status == newStatus) {
                              await vm.clearStatus();
                              return;
                            }

                            // Toggle ON / cambio scaffale
                            switch (newStatus) {
                              case ReadingStatus.toRead: {
                                int? pc = totalPages;
                                if (pc == null || pc <= 0) {
                                  pc = await _askPositiveInt(
                                    title: 'Numero pagine',
                                    label: 'Totale pagine del libro',
                                    min: 1,
                                  );
                                  if (pc == null) return;
                                }
                                await vm.setStatusWithPages(
                                  status: ReadingStatus.toRead,
                                  userBook: payload,
                                  totalPages: pc,
                                  // pagesRead: null  // opzionale: se vuoi azzerare l’avanzamento
                                );
                                break;
                              }
                              case ReadingStatus.reading: {
                                int? pc = totalPages;
                                if (pc == null || pc <= 0) {
                                  pc = await _askPositiveInt(
                                    title: 'Numero pagine',
                                    label: 'Totale pagine del libro',
                                    min: 1,
                                  );
                                  if (pc == null) return;
                                }
                                final pr = await _askPositiveInt(
                                  title: 'Pagine lette',
                                  label: 'Quante pagine hai già letto?',
                                  min: 1,
                                  max: pc,
                                  initial: vm.savedReadPages ?? 1,
                                );
                                if (pr == null) return;

                                await vm.setStatusWithPages(
                                  status: ReadingStatus.reading,
                                  userBook: payload,
                                  totalPages: pc,
                                  pagesRead: pr,
                                );
                                break;
                              }
                              case ReadingStatus.read: {
                                int? pc = totalPages;
                                if (pc == null || pc <= 0) {
                                  pc = await _askPositiveInt(
                                    title: 'Numero pagine',
                                    label: 'Totale pagine del libro',
                                    min: 1,
                                  );
                                  if (pc == null) return;
                                }
                                await vm.setStatusWithPages(
                                  status: ReadingStatus.read,
                                  userBook: payload,
                                  totalPages: pc,
                                  pagesRead: pc, // completato
                                );
                                break;
                              }
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ExpandableText(
              text: (b.description == null || b.description!.trim().isEmpty)
                  ? 'Nessuna descrizione disponibile.'
                  : b.description!,
              collapsedLines: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final int collapsedLines;
  const _ExpandableText({required this.text, this.collapsedLines = 5});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool expanded = true;
  bool overflowing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, _) {
          return Text(
            widget.text,
            maxLines: expanded ? null : widget.collapsedLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }),
        const SizedBox(height: 4),
        if (!expanded)
          TextButton(
            onPressed: () => setState(() => expanded = true),
            child: const Text('Mostra meno'),
          )
        else
          TextButton(
            onPressed: () => setState(() => expanded = false),
            child: const Text('Mostra tutto'),
          ),
      ],
    );
  }
}

class _BookStatusBar extends StatelessWidget {
  final ReadingStatus? current;
  final ValueChanged<ReadingStatus> onSet;
  final bool disabled; // NEW

  const _BookStatusBar({
    required this.current,
    required this.onSet,
    this.disabled = false, // NEW
  });

  @override
  Widget build(BuildContext context) {
    Color tint(bool checked) =>
        checked ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(.6);

    return Row(
      children: [
        IconButton(
          tooltip: 'Da leggere',
          onPressed: disabled ? null : () => onSet(ReadingStatus.toRead), // NEW
          icon: Icon(Icons.menu_book_outlined,
            color: tint(current == ReadingStatus.toRead)
          ),
        ),
        IconButton(
          tooltip: 'In lettura',
          onPressed: disabled ? null : () => onSet(ReadingStatus.reading), // NEW
          icon: Icon(Icons.auto_stories_outlined,
            color: tint(current == ReadingStatus.reading)
          ),
        ),
        IconButton(
          tooltip: 'Letto',
          onPressed: disabled ? null : () => onSet(ReadingStatus.read), // NEW
          icon: Icon(Icons.check_circle_outline,
              color: tint(current == ReadingStatus.read)
            ),
        ),
      ],
    );
  }
}

class _ReadingFlowDialogs extends StatefulWidget {
  final BookDetailViewModel vm;
  final ReadingFlowMode mode;
  final int? apiPageCount;
  final UserBook payload;
  final VoidCallback onClose;
  final VoidCallback onReachedTotal;

  const _ReadingFlowDialogs({
    required this.vm,
    required this.mode,
    required this.apiPageCount,
    required this.payload,
    required this.onClose,
    required this.onReachedTotal,
  });

  @override
  State<_ReadingFlowDialogs> createState() => _ReadingFlowDialogsState();
}

class _ReadingFlowDialogsState extends State<_ReadingFlowDialogs> {
  late bool showTotalDialog;
  late bool showReadDialog;
  late String totalPages;
  late String readPages;
  String? totalError;
  String? readError;

  @override
  void initState() {
    super.initState();
    showTotalDialog = widget.mode == ReadingFlowMode.start &&
        (widget.apiPageCount == null || widget.apiPageCount! <= 0);
    showReadDialog =
        widget.mode == ReadingFlowMode.update || (widget.apiPageCount != null && widget.apiPageCount! > 0);
    totalPages = widget.apiPageCount?.toString() ?? '';
    readPages = switch (widget.mode) {
      ReadingFlowMode.update => (widget.vm.savedReadPages?.toString() ?? ''),
      ReadingFlowMode.start  => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final max = int.tryParse(totalPages) ?? widget.apiPageCount;

    return Stack(
      children: [
        if (showTotalDialog)
          TotalPagesDialog(
            value: totalPages,
            onValue: (v) {
              setState(() {
                totalPages = v;
                final n = int.tryParse(v);
                totalError = switch (n) {
                  null => 'Inserisci un numero',
                  <= 0 => 'Deve essere > 0',
                  _ => null
                };
              });
            },
            onDismiss: () {
              setState(() => showTotalDialog = false);
              widget.onClose(); // abbandona il flusso
            },
            onConfirm: () {
              final n = int.tryParse(readPages);
              final valid = n != null && n >= 1 && (max == null || n <= max);
              if (valid) {
                final totalFromDialog = int.tryParse(totalPages);
                widget.vm.setStatusWithPages(
                  status: ReadingStatus.reading,
                  userBook: widget.payload,     // ← questo basta
                  pagesRead: n!,
                  totalPages: (widget.mode == ReadingFlowMode.start && (totalFromDialog ?? 0) > 0)
                      ? totalFromDialog
                      : null,
                );
                setState(() => showReadDialog = false);
                if (widget.mode == ReadingFlowMode.update && max != null && n == max) {
                  widget.onReachedTotal();
                }
                widget.onClose();
              }
            },
            isError: totalError != null,
            supportingText: totalError,
          ),
        if (showReadDialog)
          ReadPagesDialog(
            value: readPages,
            max: max,
            previousRead: widget.vm.savedReadPages,
            onValue: (v) {
              setState(() {
                readPages = v;
                final n = int.tryParse(v);
                readError = switch (n) {
                  null => 'Inserisci un numero',
                  < 1 => 'Devi aver letto almeno una pagina',
                  _ when max != null && n! > max => 'Non può superare $max',
                  _ => null
                };
              });
            },
            onDismiss: () {
              setState(() => showReadDialog = false);
              widget.onClose();
            },
            onConfirm: () {
              final n = int.tryParse(readPages);
              final valid = n != null && n >= 1 && (max == null || n <= max);
              if (valid) {
                final totalFromDialog = int.tryParse(totalPages);
                widget.vm.setStatusWithPages(
                  status: ReadingStatus.reading,
                  userBook: widget.payload,
                  payload: widget.payload,
                  pagesRead: n!,
                  totalPages: (widget.mode == ReadingFlowMode.start && (totalFromDialog ?? 0) > 0)
                      ? totalFromDialog
                      : null,
                );
                setState(() => showReadDialog = false);
                if (widget.mode == ReadingFlowMode.update && max != null && n == max) {
                  widget.onReachedTotal();
                }
                widget.onClose();
              }
            },
            isError: readError != null,
            supportingText: readError,
          ),
      ],
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? url;
  const _BookCover({this.url});

  @override
  Widget build(BuildContext context) {
    // normalizza: preferisci sempre https (Android blocca http cleartext)
    final safeUrl = (url == null || url!.isEmpty)
        ? null
        : url!.startsWith('http://')
            ? url!.replaceFirst('http://', 'https://')
            : url!;

    Widget placeholder() => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Icon(Icons.menu_book_outlined, size: 48),
        );

    if (safeUrl == null) return placeholder();

    return Image.network(
      safeUrl,
      fit: BoxFit.cover,
      // mostra un loader mentre scarica
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      // non far crashare il build se l'URL è invalido o fallisce il download
      errorBuilder: (_, __, ___) => placeholder(),
    );
  }
}
