import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _username;
  String? _role;
  bool _loading = false;

  String? get token => _token;
  String? get username => _username;
  String? get role => _role;
  bool get loading => _loading;
  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'ADMIN';
  bool get isAnalyst => _role == 'ANALYST' || _role == 'ADMIN';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _username = prefs.getString('username');
    _role = prefs.getString('role');
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await ApiService.login(username, password);
      if (res['success'] == true) {
        final data = res['data'];
        _token = data['token'];
        _username = data['username'];
        _role = data['role'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('username', _username!);
        await prefs.setString('role', _role!);
        notifyListeners();
        return null;
      }
      return res['message'] ?? 'Login failed';
    } catch (e) {
      return 'Connection error. Is the backend running?';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null; _username = null; _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
