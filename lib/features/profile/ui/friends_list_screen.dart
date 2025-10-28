import 'package:flutter/material.dart';
import '../model/friends_model.dart';
import '../data/friends_manager.dart';

class FriendsListScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(Friend friend) onNavigateToFriendDetails;
  const FriendsListScreen({super.key, required this.onBack, required this.onNavigateToFriendDetails});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  int _tab = 0;
  String _query = '';

  List<Friend> _friends = const [];
  List<FriendRequest> _received = const [];
  List<Friend> _allUsers = const [];
  List<String> _sent = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_tab == 0) {
        final f = await FriendsManager.loadFriends();
        if (!mounted) return;
        setState(() { _friends = f; });
      } else if (_tab == 1) {
        final r = await FriendsManager.loadReceivedRequests();
        if (!mounted) return;
        setState(() { _received = r; });
      } else {
        await FriendsManager.syncMyFriendsFromAcceptedRequests();
        final users = await FriendsManager.loadAllUsersExcludingCurrent();
        final sent = await FriendsManager.loadSentRequests();
        final fr = await FriendsManager.loadFriends();
        if (!mounted) return;
        setState(() { _allUsers = users; _sent = sent; _friends = fr; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = (_tab == 0
        ? _friends
        : _tab == 2
            ? _allUsers
            : const <Friend>[])
        .where((f) => f.matches(_query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Amici'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip('Amici', 0),
                    const SizedBox(width: 8),
                    _chip('Richieste', 1),
                    const SizedBox(width: 8),
                    _chip('Utenti', 2),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const _Loading()
                : (_error != null)
                    ? _CenteredMessage('Errore: $_error')
                    : _buildContent(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Friend> filtered) {
    if (_tab == 1) {
      if (_received.isEmpty) return const _CenteredMessage('Nessuna richiesta ricevuta');
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _received.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final req = _received[i];
          return _RequestItem(
            request: req,
            onAccept: () async {
              final r = await FriendsManager.acceptFriendRequest(req);
              if (r.$1) {
                if (!mounted) return;
                setState(() { _received = _received.where((e) => e.id != req.id).toList(); });
                final nf = await FriendsManager.loadFriends();
                if (!mounted) return;
                setState(() { _friends = nf; });
              } else {
                if (!mounted) return;
                setState(() { _error = r.$2; });
              }
            },
            onReject: () async {
              final r = await FriendsManager.rejectFriendRequest(req);
              if (r.$1) {
                if (!mounted) return;
                setState(() { _received = _received.where((e) => e.id != req.id).toList(); });
              } else {
                if (!mounted) return;
                setState(() { _error = r.$2; });
              }
            },
          );
        },
      );
    }

    if (filtered.isEmpty) {
      final msg = _query.isNotEmpty
          ? "Nessun risultato per '$_query'"
          : _tab == 0
              ? 'Nessun amico trovato'
              : 'Nessun utente trovato';
      return _CenteredMessage(msg);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final f = filtered[i];
        final isUsers = _tab == 2;
        return _FriendItem(
          friend: f,
          isInUsersSection: isUsers,
          friendsList: _friends,
          sentRequestsList: _sent,
          onSendRequest: (ff) async {
            final r = await FriendsManager.sendFriendRequest(ff.uid);
            if (r.$1) {
              if (!mounted) return;
              setState(() { _sent = [..._sent, ff.uid]; });
            } else {
              if (!mounted) return;
              setState(() { _error = r.$2; });
            }
          },
          onFriendClick: (ff) async {
            if (!isUsers) {
              widget.onNavigateToFriendDetails(ff);
            }
          },
        );
      },
    );
  }

  Widget _chip(String label, int idx) => ChoiceChip(
        label: Text(label),
        selected: _tab == idx,
        onSelected: (_) async { setState(() => _tab = idx); await _load(); },
      );
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _CenteredMessage extends StatelessWidget {
  final String msg;
  const _CenteredMessage(this.msg);
  @override
  Widget build(BuildContext context) => Center(child: Text(msg));
}

class _FriendItem extends StatelessWidget {
  final Friend friend;
  final bool isInUsersSection;
  final List<Friend> friendsList;
  final List<String> sentRequestsList;
  final void Function(Friend) onSendRequest;
  final void Function(Friend) onFriendClick;
  const _FriendItem({
    required this.friend,
    required this.isInUsersSection,
    required this.friendsList,
    required this.sentRequestsList,
    required this.onSendRequest,
    required this.onFriendClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => onFriendClick(friend),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.fullName, style: Theme.of(context).textTheme.titleMedium),
                    if (friend.username.isNotEmpty)
                      Text('@${friend.username}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (isInUsersSection)
                _action(friend),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(Friend f) {
    final status = FriendsManager.relationshipStatus(f, friendsList, sentRequestsList);
    switch (status) {
      case UserRelationshipStatus.notFriend:
        return IconButton(icon: const Icon(Icons.person_add_alt_1), onPressed: () => onSendRequest(f));
      case UserRelationshipStatus.pending:
        return const Icon(Icons.schedule);
      case UserRelationshipStatus.isFriend:
        return const Icon(Icons.check_circle, color: Colors.blue);
    }
  }
}

class _RequestItem extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _RequestItem({required this.request, required this.onAccept, required this.onReject});
  @override
  State<_RequestItem> createState() => _RequestItemState();
}

class _RequestItemState extends State<_RequestItem> {
  Friend? _sender;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _sender = await FriendsManager.loadUserById(widget.request.fromUid);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sender?.fullName ?? 'Caricamento...', style: Theme.of(context).textTheme.titleMedium),
                  if ((_sender?.username ?? '').isNotEmpty)
                    Text('@${_sender!.username}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: widget.onReject),
            IconButton(icon: const Icon(Icons.check), color: Colors.green, onPressed: widget.onAccept),
          ],
        ),
      ),
    );
  }
}
