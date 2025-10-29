import 'package:flutter/material.dart';

class AppSearchBar extends StatefulWidget {
  final String text;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;
  final bool autofocus;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;

  const AppSearchBar({
    super.key,
    required this.text,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = 'Cerca…',
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 6),
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  late final ValueNotifier<bool> _hasText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _hasText = ValueNotifier(widget.text.isNotEmpty);
    _controller.addListener(() => _hasText.value = _controller.text.isNotEmpty);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se il testo esterno cambia (es. vm.clearSearch), sincronizza il controller.
    if (widget.text != _controller.text) {
      final pos = TextSelection.collapsed(offset: widget.text.length);
      _controller.value = TextEditingValue(text: widget.text, selection: pos);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          suffixIcon: ValueListenableBuilder<bool>(
            valueListenable: _hasText,
            builder: (_, hasText, __) {
              if (!hasText) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Pulisci',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  // Aggiorna UI + notifica i callback esterni
                  _controller.clear();
                  widget.onChanged('');
                  widget.onClear?.call();
                },
              );
            },
          ),
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
