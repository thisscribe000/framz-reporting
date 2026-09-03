import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  bool get isAdmin => _user?['role'] == 'ADMIN';
  bool get isPastor => _user?['role'] == 'PASTOR' || isAdmin;
  bool get isFinance => _user?['role'] == 'FINANCE' || isPastor;
  bool get isAttendance => _user?['role'] == 'ATTENDANCE' || isPastor;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();
    final currentUser = await ApiService.getMe();
    _user = currentUser;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    final res = await ApiService.login(email, password);
    _isLoading = false;
    if (res['success'] == true) {
      _user = res['user'];
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }
}
