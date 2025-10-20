import 'package:flutter/material.dart';
import '../viewmodel/shelves_view_model.dart';
import 'selected_shelf_screen.dart';

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
                  settings: RouteSettings(
                    arguments: SelectedShelfArgs(status: status),
                  ),
                ),
              );
            },
          );
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
