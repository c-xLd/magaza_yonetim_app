import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  String? _displayName;
  String? _phoneNumber;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get displayName => _displayName;
  String? get phoneNumber => _phoneNumber;
  String? get role => _role;

  // Oturum durumunu kontrol et
  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username');
      _displayName = prefs.getString('displayName');
      _phoneNumber = prefs.getString('phoneNumber');
      _role = prefs.getString('role');
      notifyListeners();
    } catch (e) {
      debugPrint('SharedPreferences hatası: $e');
    }
  }

  Future<bool> login(String username, {String? role}) async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = true;
    _username = username;
    _displayName = username; // Varsayılan olarak kullanıcı adı
    if (role != null) {
    _role = role;
    } else {
      _role = 'staff';
    }
    debugPrint('LOGIN: Kullanıcı rolü -> [32m[1m$_role[0m');
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setString('username', _username!);
    await prefs.setString('displayName', _displayName!);
      await prefs.setString('role', _role!);
    notifyListeners();
    return true;
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isLoggedIn = false;
      _username = null;
      _displayName = null;
      _phoneNumber = null;
      _role = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
    }
  }

  // Telefon kontrolü
  Future<bool> checkPhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _phoneNumber = phone;
      await prefs.setString('phoneNumber', phone);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Telefon kayıt hatası: $e');
      return false;
    }
  }

  // Kod doğrulama
  Future<bool> verifyCode(String code) async {
    // Test için sabit kod: 123456
    if (code == '123456') {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Doğrulama kayıt hatası: $e');
      }
    }
    return false;
  }

  // Kullanıcıya gösterilecek rol adını teknik değerden Türkçe ve kullanıcı dostu bir isme çeviren fonksiyon
  static String getDisplayRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Yönetici';
      case 'manager':
        return 'Mağaza Sorumlusu';
      case 'staff':
        return 'Mağaza Personeli';
      default:
        return 'Kullanıcı';
    }
  }

  Future<bool> checkLoginStatusAsync() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    _isLoggedIn = firebaseUser != null;
    notifyListeners();
    return _isLoggedIn;
  }

  // Uygulama başında hem SharedPreferences hem de Firebase Auth ile oturum kontrolü
  Future<void> initialize() async {
    await checkLoginStatus(); // SharedPreferences kontrolü
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _isLoggedIn = true;
      // Firebase'den kullanıcı bilgileri çekilebilir (isteğe bağlı)
    }
    notifyListeners();
  }
}
