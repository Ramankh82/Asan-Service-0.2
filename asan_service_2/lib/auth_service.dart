import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

enum AuthState { unknown, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  String? _token;
  Map<String, dynamic>? _userPayload;
  AuthState _authState = AuthState.unknown;
  bool _isInitialized = false;

  String? get token => _token;
  AuthState get authState => _authState;
  String? get userRole => _userPayload?['role'];
  String? get userPhoneNumber => _userPayload?['phone_number'];
  String? get userId => _userPayload?['user_id'];
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _token = await _storage.read(key: 'auth_token');
      if (_token != null) {
        _decodeToken(_token!);
        _authState = AuthState.authenticated;
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      await _storage.delete(key: 'auth_token');
      _authState = AuthState.unauthenticated;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _decodeToken(String token) {
    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      _userPayload = json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid token format');
    }
  }

  Future<void> login(String token) async {
    try {
      _token = token;
      _decodeToken(token);
      await _storage.write(key: 'auth_token', value: token);
      _authState = AuthState.authenticated;
      notifyListeners();
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _token = null;
      _userPayload = null;
      _authState = AuthState.unauthenticated;
      await _storage.delete(key: 'auth_token');
      notifyListeners();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<void> clearAuthData() async {
    try {
      await _storage.deleteAll();
      _token = null;
      _userPayload = null;
      _authState = AuthState.unauthenticated;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to clear auth data: $e');
    }
  }
}