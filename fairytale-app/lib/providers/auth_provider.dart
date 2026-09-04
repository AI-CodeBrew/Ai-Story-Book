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
      final googleSignIn = GoogleSignIn();
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
}
