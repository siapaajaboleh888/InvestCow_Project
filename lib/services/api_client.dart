import 'package:flutter/foundation.dart';

class ApiClient {
  /// Base URL yang digunakan untuk koneksi ke backend.
  /// Bisa di-override lewat --dart-define=BASE_URL=https://api.anda.com
  final String baseUrl;

  ApiClient({String? overrideBaseUrl})
      : baseUrl = overrideBaseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    // 1. Cek jika ada override dari --dart-define (Sangat berguna untuk CI/CD Hosting)
    const defineUrl = String.fromEnvironment('BASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    // 2. Jika mode Rilis (Production/Hosting)
    if (kReleaseMode) {
      // GANTI ini ke URL hosting backend Anda nantinya
      return 'https://api.investcow.id'; 
    }

    // 3. Jika mode Debug/Profile (Pengembangan)
    if (kIsWeb) {
      return 'http://localhost:8081';
    } else {
      // Emulator Android (10.0.2.2) vs Physical Device (Gunakan IP Local PC Anda)
      // Tips: Gunakan IP static laptop agar tidak berubah-ubah
      return 'http://192.168.1.111:8081'; 
    }
  }

  String get socketUrl => baseUrl;

  Uri uri(String path, [Map<String, dynamic>? query]) {
    // Pastikan baseUrl tidak diakhiri / dan path dimulai /
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    
    return Uri.parse('$cleanBase$cleanPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Map<String, String> jsonHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
