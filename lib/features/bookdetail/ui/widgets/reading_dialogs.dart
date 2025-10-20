import 'package:flutter/material.dart';

class TotalPagesDialog extends StatelessWidget {
  final String value;
  final ValueChanged<String> onValue;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final bool isError;
  final String? supportingText;

  const TotalPagesDialog({
    super.key,
    required this.value,
    required this.onValue,
    required this.onDismiss,
    required this.onConfirm,
    required this.isError,
    required this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Inserisci pagine totali', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pagine totali',
                  errorText: isError ? supportingText : null,
                ),
                controller: TextEditingController(text: value),
                onChanged: (s) => onValue(s.replaceAll(RegExp(r'[^0-9]'), '')),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onDismiss, child: const Text('Annulla')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: value.isNotEmpty && !isError ? onConfirm : null,
                    child: const Text('Salva'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReadPagesDialog extends StatelessWidget {
  final String value;
  final int? max;
  final int? previousRead;
  final ValueChanged<String> onValue;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final bool isError;
  final String? supportingText;

  const ReadPagesDialog({
    super.key,
    required this.value,
    required this.max,
    required this.previousRead,
    required this.onValue,
    required this.onDismiss,
    required this.onConfirm,
    required this.isError,
    required this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    final typed = int.tryParse(value);
    final display = typed ?? previousRead;
    final title = switch ((max, display)) {
      (final m?, final d?) => 'Pagine lette ($d/$m)',
      (final m?, _)       => 'Pagine lette (1..$m)',
      _                   => 'Pagine lette',
    };

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Pagine lette',
                  errorText: isError ? supportingText : null,
                ),
                controller: TextEditingController(text: value),
                onChanged: (s) => onValue(s.replaceAll(RegExp(r'[^0-9]'), '')),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onDismiss, child: const Text('Annulla')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: value.isNotEmpty && !isError ? onConfirm : null,
                    child: const Text('Salva'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
