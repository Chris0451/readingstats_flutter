import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/viewmodel/profile_view_model.dart';
import '../model/user_model.dart';
import '../ui/friends_list_screen.dart';
import '../ui/friend_details_screen.dart';

enum _ProfileSubpage { profile, dati, edit, info }

class ProfileScreen extends StatefulWidget {
  final ProfileViewModel vm;
  final VoidCallback onLogout;
  final VoidCallback onNavigateToFriends;

  const ProfileScreen({
    super.key,
    required this.vm,
    required this.onLogout,
    required this.onNavigateToFriends,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileSubpage _page = _ProfileSubpage.profile;

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    super.dispose();
  }

  void _onVm() {
    if (widget.vm.updateResult == 'success' && _page == _ProfileSubpage.edit) {
      setState(() => _page = _ProfileSubpage.dati);
      widget.vm.clearUpdateResult();
    }
  }

  Future<bool> _onWillPop() async {
    if (_page != _ProfileSubpage.profile) {
      setState(() => _page = _ProfileSubpage.profile);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnimatedBuilder(
        animation: widget.vm,
        builder: (context, _) {
          final user = widget.vm.user;
          switch (_page) {
            case _ProfileSubpage.profile:
              return _ProfileRoot(
                user: user,
                onDatiPersonali: () => setState(() => _page = _ProfileSubpage.dati),
                onListaAmici: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendsListScreen(
                        onBack: () => Navigator.of(context).pop(),
                        onNavigateToFriendDetails: (f) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FriendDetailsScreen(friend: f),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                onInfoSupporto: () => setState(() => _page = _ProfileSubpage.info),
                onLogout: () async {
                  await FirebaseAuth.instance.signOut();
                  widget.onLogout();
                },
              );
            case _ProfileSubpage.dati:
              return _DatiPersonali(
                user: user,
                onBack: () => setState(() => _page = _ProfileSubpage.profile),
                onEdit: () => setState(() => _page = _ProfileSubpage.edit),
              );
            case _ProfileSubpage.edit:
              return _ModificaDatiPersonali(
                user: user,
                isLoading: widget.vm.updateLoading,
                onSave: (username, name, surname, email) {
                  widget.vm.updateUserProfile(
                    username: username,
                    name: name,
                    surname: surname,
                    email: email,
                  );
                },
                onCancel: () => setState(() => _page = _ProfileSubpage.dati),
                error: widget.vm.updateResult == 'error_username_taken'
                    ? 'Username non disponibile'
                    : widget.vm.updateResult == 'error_update_failed'
                        ? 'Errore durante l\'aggiornamento'
                        : null,
              );
            case _ProfileSubpage.info:
              return _InfoSupporto(
                onBack: () => setState(() => _page = _ProfileSubpage.profile),
                onAccountDeleted: () async {
                  try {
                    await FirebaseAuth.instance.currentUser?.delete();
                  } catch (_) {}
                  await FirebaseAuth.instance.signOut();
                  widget.onLogout();
                },
              );
          }
        },
      ),
    );
  }
}

class _ProfileRoot extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onLogout;
  final VoidCallback onDatiPersonali;
  final VoidCallback onListaAmici;
  final VoidCallback onInfoSupporto;

  const _ProfileRoot({
    required this.user,
    required this.onLogout,
    required this.onDatiPersonali,
    required this.onListaAmici,
    required this.onInfoSupporto,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundImage: NetworkImage(
                    'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.username ?? 'Caricamento...',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if ((user?.email ?? '').isNotEmpty)
                  Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Dati personali'),
                  subtitle: const Text('Visualizza e modifica'),
                  onTap: onDatiPersonali,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Lista amici'),
                  subtitle: const Text('Gestisci amicizie'),
                  onTap: onListaAmici,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Info e supporto'),
                  subtitle: const Text('Guida e contatti'),
                  onTap: onInfoSupporto,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Esci dal profilo'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatiPersonali extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _DatiPersonali({
    required this.user,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: onBack),
        title: const Text('Dati personali'),
        actions: [IconButton(onPressed: onEdit, icon: const Icon(Icons.edit))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Username', value: user?.username),
            _Field(label: 'Nome', value: user?.name),
            _Field(label: 'Cognome', value: user?.surname),
            _Field(label: 'Email', value: user?.email),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value ?? '-', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ModificaDatiPersonali extends StatefulWidget {
  final UserModel? user;
  final void Function(String username, String name, String surname, String email) onSave;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? error;

  const _ModificaDatiPersonali({
    required this.user,
    required this.onSave,
    required this.onCancel,
    required this.isLoading,
    this.error,
  });

  @override
  State<_ModificaDatiPersonali> createState() => _ModificaDatiPersonaliState();
}

class _ModificaDatiPersonaliState extends State<_ModificaDatiPersonali> {
  late final TextEditingController _username =
      TextEditingController(text: widget.user?.username ?? '');
  late final TextEditingController _name =
      TextEditingController(text: widget.user?.name ?? '');
  late final TextEditingController _surname =
      TextEditingController(text: widget.user?.surname ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.user?.email ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _surname.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !widget.isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onCancel),
        title: const Text('Modifica dati'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
              ),
              TextFormField(
                controller: _surname,
                decoration: const InputDecoration(labelText: 'Cognome'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email non valida' : null,
              ),
              const SizedBox(height: 12),
              if (widget.error != null)
                Text(widget.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(onPressed: canSubmit ? widget.onCancel : null, child: const Text('Annulla')),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: canSubmit
                        ? () {
                            if (_formKey.currentState?.validate() == true) {
                              widget.onSave(
                                _username.text,
                                _name.text,
                                _surname.text,
                                _email.text,
                              );
                            }
                          }
                        : null,
                    child: widget.isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salva'),
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

class _InfoSupporto extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onAccountDeleted;
  const _InfoSupporto({required this.onBack, required this.onAccountDeleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: onBack), title: const Text('Info e supporto')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guida e contatti', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Per assistenza contatta lo sviluppatore o consulta la documentazione interna.'),
            const Spacer(),
            FilledButton.icon(
              onPressed: onAccountDeleted,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Elimina account'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
