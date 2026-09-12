import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _token;
  Map<String, dynamic>? _user;
  bool _initializing = true;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get initializing => _initializing;
  Set<String> get favoriteIds => Set<String>.from((_user?['favoriteStoryIds'] as List?) ?? const []);
  bool isFavorite(String storyId) => favoriteIds.contains(storyId);

  Future<void> loadFromStorage() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        _token = token;
        _user = await ApiService.me(token);
      }
    } catch (e) {
      // Expired/invalid token — treat as logged out.
      _token = null;
      _user = null;
      await _storage.delete(key: _tokenKey);
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> _applySession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _user = Map<String, dynamic>.from(data['user'] as Map);
    await _storage.write(key: _tokenKey, value: _token);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      await _applySession(await ApiService.login(email, password));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name) async {
    try {
      await _applySession(await ApiService.signup(email, password, name));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '856554896829-fdl18nar55lvt7mg0lnj9qn999h1ldd0.apps.googleusercontent.com',
      );
      final account = await googleSignIn.signIn();
      if (account == null) return false; // user cancelled
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return false;
      await _applySession(await ApiService.googleLogin(idToken));
      return true;
    } catch (e) {
      if (kDebugMode) print('Google sign-in error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }

  /// Permanently deletes the account and all owned stories server-side,
  /// then clears the local session.
  Future<bool> deleteAccount() async {
    final token = _token;
    if (token == null) return false;
    try {
      await ApiService.deleteAccount(token);
      await logout();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateName(String name) async {
    final token = _token;
    if (token == null) return false;
    try {
      _user = await ApiService.updateProfile(name, token);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Optimistically toggles favorite state, then reverts if the request fails.
  Future<void> toggleFavorite(String storyId) async {
    final token = _token;
    if (token == null) return;
    final wasFavorite = isFavorite(storyId);
    final updated = Set<String>.from(favoriteIds);
    wasFavorite ? updated.remove(storyId) : updated.add(storyId);
    _user = {...?_user, 'favoriteStoryIds': updated.toList()};
    notifyListeners();
    try {
      if (wasFavorite) {
        await ApiService.removeFavorite(storyId, token);
      } else {
        await ApiService.addFavorite(storyId, token);
      }
    } catch (e) {
      final reverted = Set<String>.from(updated);
      wasFavorite ? reverted.add(storyId) : reverted.remove(storyId);
      _user = {...?_user, 'favoriteStoryIds': reverted.toList()};
      notifyListeners();
      if (kDebugMode) print('Toggle favorite error: $e');
    }
  }
}
