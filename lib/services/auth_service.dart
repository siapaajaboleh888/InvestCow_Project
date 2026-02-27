import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

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
  static const String _keyToken = 'auth_token';
  static const String _keyRole = 'user_role';
  static const String _keyProfilePicture = 'profile_picture';

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

  Future<void> loginWithBackend(String email, String password,
      {bool rememberMe = false}) async {
    final client = ApiClient();
    final uri = client.uri('/auth/login');
    final res = await http
        .post(uri, headers: client.jsonHeaders(), body: jsonEncode({
      'email': email,
      'password': password,
    }));

    if (res.statusCode != 200) {
      throw Exception('Login gagal (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, (data['display_name'] ?? 'User').toString());
    await prefs.setString(_keyUserId, data['id'].toString());
    await prefs.setString(_keyRole, (data['role'] ?? 'user').toString());
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setString(_keyLoginMethod, 'email');
    await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());
    
    if (data['profile_picture'] != null) {
      await prefs.setString(_keyProfilePicture, data['profile_picture'].toString());
    }
    
    if (data['token'] != null) {
      await prefs.setString(_keyToken, data['token']);
    }
  }

  Future<void> registerWithBackend({
    required String displayName,
    required String email,
    required String password,
    String? locale,
  }) async {
    final client = ApiClient();
    final uri = client.uri('/auth/register');
    final res = await http.post(
      uri,
      headers: client.jsonHeaders(),
      body: jsonEncode({
        'display_name': displayName,
        'email': email,
        'password': password,
        'locale': locale,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Registrasi gagal (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, displayName);
    await prefs.setString(_keyUserId, data['id'].toString());
    await prefs.setBool(_keyRememberMe, true);
    await prefs.setString(_keyLoginMethod, 'email');
    await prefs.setString(_keyLoginTimestamp, DateTime.now().toIso8601String());
    
    if (data['profile_picture'] != null) {
      await prefs.setString(_keyProfilePicture, data['profile_picture'].toString());
    }
    
    if (data['token'] != null) {
      await prefs.setString(_keyToken, data['token']);
    }
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

  /// Ambil role user (user/admin)
  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole) ?? 'user';
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
    
    // Sync with backend
    final client = ApiClient();
    final token = await getToken();
    final uri = client.uri('/auth/me');
    await http.patch(
      uri,
      headers: client.jsonHeaders(token: token),
      body: jsonEncode({
        'display_name': name,
        'email': email,
      }),
    );
  }

  /// Update foto profil (base64)
  Future<void> updateProfilePicture(String base64Image) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePicture, base64Image);
    
    // Sync with backend
    final client = ApiClient();
    final token = await getToken();
    final uri = client.uri('/auth/me');
    final res = await http.patch(
      uri,
      headers: client.jsonHeaders(token: token),
      body: jsonEncode({'profile_picture': base64Image}),
    );
    
    if (res.statusCode != 200) {
      throw Exception('Gagal menyimpan foto ke server');
    }
  }

  /// Ambil foto profil (base64)
  Future<String?> getProfilePicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfilePicture);
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
      'role': prefs.getString(_keyRole) ?? 'user',
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
    await prefs.remove(_keyToken);
    await prefs.remove(_keyProfilePicture);
    // Keep remember me preference
  }

  /// Ambil token JWT jika ada
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Hapus akun di backend dan bersihkan sesi lokal
  Future<void> deleteAccount() async {
    final token = await getToken();
    final client = ApiClient();
    final uri = client.uri('/auth/me');

    final res = await http.delete(
      uri,
      headers: client.jsonHeaders(token: token ?? ''),
    );

    if (res.statusCode != 204) {
      throw Exception('Gagal menghapus akun (${res.statusCode})');
    }

    await logout();
  }

  Future<Map<String, dynamic>> getMe() async {
    final client = ApiClient();
    final token = await getToken();
    final uri = client.uri('/auth/me');
    final res = await http.get(uri, headers: client.jsonHeaders(token: token));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengambil data user (${res.statusCode})');
    }
    return jsonDecode(res.body);
  }

  Future<void> topUp(double amount, {String? method}) async {
    final client = ApiClient();
    final token = await getToken();
    final uri = client.uri('/auth/topup');
    final res = await http.post(
      uri,
      headers: client.jsonHeaders(token: token),
      body: jsonEncode({
        'amount': amount,
        'method': method,
      }),
    );
    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);
      throw Exception(data['message'] ?? 'Gagal top up (${res.statusCode})');
    }
  }
}
