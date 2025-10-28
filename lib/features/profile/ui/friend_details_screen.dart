import 'package:flutter/material.dart';
import '../model/friends_model.dart';
import '../data/friends_manager.dart';

class FriendDetailsScreen extends StatefulWidget {
  final Friend friend;
  const FriendDetailsScreen({super.key, required this.friend});

  @override
  State<FriendDetailsScreen> createState() => _FriendDetailsScreenState();
}

class _FriendDetailsScreenState extends State<FriendDetailsScreen> {
  List<FriendBook> _books = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await FriendsManager.loadUserWithBooksIfFriend(widget.friend.uid);
    if (!mounted) return;
    setState(() {
      _books = res.$2 ?? const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reading = _books.where((b) => b.status == 'READING').toList();
    final completed = _books.where((b) => b.status == 'READ').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Amico'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_remove),
            onPressed: () async {
              final ok = await _confirm(context, 'Rimuovere amicizia con @${widget.friend.username}?');
              if (ok == true) {
                final r = await FriendsManager.removeFriend(widget.friend.uid);
                if (r.$1 && mounted) Navigator.of(context).maybePop();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(widget.friend),
                const SizedBox(height: 16),
                _stats(_books),
                const SizedBox(height: 16),
                _section('In lettura (${reading.length})', reading),
                const SizedBox(height: 16),
                _section('Completati (${completed.length})', completed.take(3).toList()),
              ],
            ),
    );
  }

  Widget _header(Friend f) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(radius: 48, child: Icon(Icons.account_circle, size: 48)),
              const SizedBox(height: 12),
              Text(f.username, style: Theme.of(context).textTheme.titleLarge),
              Text(f.fullName, style: Theme.of(context).textTheme.bodyMedium),
              if (f.email.isNotEmpty) Text(f.email, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );

  Widget _stats(List<FriendBook> all) {
    final total = all.fold<int>(0, (p, e) => p + (e.totalReadSeconds ?? 0));
    final completed = all.where((b) => b.status == 'READ').length;
    final avg = completed > 0 ? (total ~/ completed) : 0;
    return Card(
      color: const Color(0xFFE3F2FD),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistiche di lettura', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Tempo totale: ${_fmt(total)}'),
            Text('Completati: $completed'),
            Text('Tempo medio/libro: ${_fmt(avg)}'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<FriendBook> books) => Card(
        color: const Color(0xFFFFF3E0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (books.isEmpty) const Text('Nessun elemento')
              else ...books.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b.title, maxLines: 2)),
                        const SizedBox(width: 8),
                        Text(_fmt(b.totalReadSeconds ?? 0)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );

  String _fmt(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '$h ore, $m minuti';
    if (m > 0) return '$m minuti';
    return '< 1 minuto';
  }
}

Future<bool?> _confirm(BuildContext context, String msg) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annulla')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Conferma')),
      ],
    ),
  );
}
