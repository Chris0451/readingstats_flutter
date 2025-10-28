import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/profile_repository.dart';
import '../model/user_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repo;
  ProfileViewModel(this._repo) {
    _loadCurrentUser();
  }

  UserModel? _user;
  bool _loading = false;
  bool _updateLoading = false;
  String? _updateResult;

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get updateLoading => _updateLoading;
  String? get updateResult => _updateResult;

  Future<void> _loadCurrentUser() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _repo.getCurrentUserProfile();
    } catch (_) {} finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String username,
    required String name,
    required String surname,
    required String email,
  }) async {
    _updateLoading = true;
    _updateResult = null;
    notifyListeners();
    try {
      await _repo.updateUserProfile(
        username: username,
        name: name,
        surname: surname,
        email: email,
      );
      if (_user != null) {
        _user = _user!.copyWith(
          username: username,
          name: name,
          surname: surname,
          email: email,
        );
      } else {
        _user = await _repo.getCurrentUserProfile();
      }
      _updateResult = 'success';
    } on FirebaseException catch (e) {
      _updateResult =
          e.code == 'username-taken' ? 'error_username_taken' : 'error_update_failed';
    } catch (_) {
      _updateResult = 'error_update_failed';
    } finally {
      _updateLoading = false;
      notifyListeners();
    }
  }

  void clearUpdateResult() {
    _updateResult = null;
    notifyListeners();
    }
}
