import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk handle autentikasi user
class AuthService {
  // Keys untuk menyimpan data di SharedPreferences
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLoginMethod =
      'login_method'; // email, facebook, google
  static const String _keyUserId = 'user_id';
  static const String _keyLoginTimestamp = 'login_timestamp';

  // Singleton pattern - hanya ada 1 instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    // Cek remember me - jika tidak dicentang dan sudah lewat 24 jam, auto logout
    if (isLoggedIn) {
      final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
      if (!rememberMe) {
        final timestamp = prefs.getString(_keyLoginTimestamp);
        if (timestamp != null) {
          final loginTime = DateTime.parse(timestamp);
          final now = DateTime.now();
          final difference = now.difference(loginTime);

          // Auto logout setelah 24 jam jika tidak remember me
          if (difference.inHours > 24) {
            await logout();
            return false;
          }
        }
      }
    }

    return isLoggedIn;
  }

  /// Login user dengan email/password - simpan data ke SharedPreferences
  Future<void> login(
    String name,
    String email, {
    bool rememberMe = false,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setString(_keyLoginMethod, 'email');
    await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());

    if (userId != null) {
      await prefs.setString(_keyUserId, userId);
    }
  }

  /// Login dengan Facebook
  Future<void> loginWithFacebook(
    String name,
    String email,
    String userId, {
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setString(_keyLoginMethod, 'facebook');
    await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());
  }

  /// Login dengan Google
  Future<void> loginWithGoogle(
    String name,
    String email,
    String userId, {
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setString(_keyLoginMethod, 'google');
    await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());
  }

  /// Logout user - hapus semua data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data
  }

  /// Ambil nama user
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  /// Ambil email user
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  /// Ambil user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  /// Ambil login method (email, facebook, google)
  Future<String?> getLoginMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginMethod);
  }

  /// Cek apakah remember me aktif
  Future<bool> isRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Update profil user
  Future<void> updateProfile(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
  }

  /// Update remember me setting
  Future<void> updateRememberMe(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  /// Get user data as Map
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!isLoggedIn) return null;

    return {
      'name': prefs.getString(_keyUserName),
      'email': prefs.getString(_keyUserEmail),
      'userId': prefs.getString(_keyUserId),
      'loginMethod': prefs.getString(_keyLoginMethod),
      'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
      'loginTimestamp': prefs.getString(_keyLoginTimestamp),
    };
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate password strength (minimal 6 karakter)
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Clear specific user data (keep settings)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyLoginMethod);
    await prefs.remove(_keyLoginTimestamp);
    // Keep remember me preference
  }
}
