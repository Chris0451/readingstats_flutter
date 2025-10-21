import 'package:flutter/material.dart';
import '../../model/ui_home_book.dart';

class PagesDialog extends StatefulWidget {
  final UiHomeBook book;
  final int initial;
  final VoidCallback onDismiss;
  final ValueChanged<int> onConfirm;

  const PagesDialog({
    super.key,
    required this.book,
    required this.initial,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<PagesDialog> createState() => _PagesDialogState();
}

class _PagesDialogState extends State<PagesDialog> {
  late final TextEditingController _c;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial.toString());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool _validate() {
    final max = widget.book.pageCount;
    final v = int.tryParse(_c.text.trim());
    setState(() {
      _error = switch (v) {
        null => 'Inserisci un numero',
        < 0 => 'Deve essere ≥ 0',
        _ when max != null && v > max => 'Non può superare $max',
        _ => null
      };
    });
    return _error == null;
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.book.pageCount;

    return Center(
      child: Material(
        color: Colors.black26,
        child: AlertDialog(
          title: Text(max != null ? 'Pagine lette (0..$max)' : 'Pagine lette'),
          content: TextField(
            controller: _c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Pagine lette totali',
              isDense: true,
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) _validate();
            },
          ),
          actions: [
            TextButton(onPressed: widget.onDismiss, child: const Text('Annulla')),
            FilledButton(
              onPressed: () {
                if (_validate()) {
                  widget.onConfirm(int.parse(_c.text.trim()));
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }
}
