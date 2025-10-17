import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../model/auth_state.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  AuthViewModel(this._repo);

  LoginUiState _login = const LoginUiState();
  LoginUiState get login => _login;

  RegisterUiState _reg = const RegisterUiState();
  RegisterUiState get reg => _reg;

  Stream<User?> get authState => _repo.authState();

  // ---- LOGIN ----
  void onLoginEmailChange(String v) { _login = _login.copyWith(email: v, error: null); notifyListeners(); }
  void onLoginPasswordChange(String v) { _login = _login.copyWith(password: v, error: null); notifyListeners(); }

  Future<void> submitLogin() async {
    if (!_login.canSubmit) return;
    _login = _login.copyWith(isSubmitting: true, error: null, success: false);
    notifyListeners();
    try {
      await _repo.login(email: _login.email.trim(), password: _login.password.trim());
      _login = _login.copyWith(isSubmitting: false, success: true);
    } on FirebaseAuthException catch (e) {
      _login = _login.copyWith(isSubmitting: false, error: _mapAuthCode(e.code));
    } catch (_) {
      _login = _login.copyWith(isSubmitting: false, error: 'Errore imprevisto. Riprova.');
    }
    notifyListeners();
  }

  // ---- REGISTER ----
  Timer? _usernameTimer;

  void onNameChange(String v) { _reg = _reg.copyWith(name: v, error: null); notifyListeners(); }
  void onSurnameChange(String v) { _reg = _reg.copyWith(surname: v, error: null); notifyListeners(); }

  void onUsernameChange(String v) {
    _reg = _reg.copyWith(username: v, usernameAvailable: null, error: null);
    notifyListeners();
    _usernameTimer?.cancel();
    _usernameTimer = Timer(const Duration(milliseconds: 400), () async {
      final ok = await _repo.isUsernameAvailable(v.trim());
      _reg = _reg.copyWith(usernameAvailable: ok);
      notifyListeners();
    });
  }

  void onEmailChange(String v) { _reg = _reg.copyWith(email: v, error: null); notifyListeners(); }
  void onPasswordChange(String v) { _reg = _reg.copyWith(password: v, error: null); notifyListeners(); }
  void onConfirmPasswordChange(String v) { _reg = _reg.copyWith(confirmPassword: v, error: null); notifyListeners(); }

  Future<void> submitRegister() async {
    if (!_reg.canSubmit) return;
    _reg = _reg.copyWith(isSubmitting: true, error: null, success: false);
    notifyListeners();
    try {
      await _repo.register(
        name: _reg.name.trim(),
        surname: _reg.surname.trim(),
        username: _reg.username.trim(),
        email: _reg.email.trim(),
        password: _reg.password.trim(),
      );
      _reg = _reg.copyWith(isSubmitting: false, success: true);
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'username-taken'
          ? 'Username non disponibile.'
          : _mapAuthCode(e.code);
      _reg = _reg.copyWith(isSubmitting: false, error: msg);
    } on FirebaseException catch (e) {
      _reg = _reg.copyWith(isSubmitting: false, error: 'Firestore: ${e.code}');
    } catch (_) {
      _reg = _reg.copyWith(isSubmitting: false, error: 'Errore imprevisto. Riprova.');
    }
    notifyListeners();
  }

  Future<void> logout() => _repo.logout();

  String _mapAuthCode(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email già in uso.';
      case 'invalid-email': return 'Email non valida.';
      case 'weak-password': return 'Password troppo debole.';
      case 'user-not-found': return 'Utente non trovato.';
      case 'wrong-password': return 'Credenziali non valide.';
      case 'invalid-credential': return 'Credenziali non valide.';
      case 'too-many-requests': return 'Troppe richieste. Attendi e riprova.';
      default: return 'Errore di autenticazione ($code).';
    }
  }

  @override
  void dispose() {
    _usernameTimer?.cancel();
    super.dispose();
  }
}
