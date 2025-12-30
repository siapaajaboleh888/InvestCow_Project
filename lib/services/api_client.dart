import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  // Default base URL: Android emulator uses 10.0.2.2, desktop/iOS uses localhost
  // Untuk device fisik, ganti ke IP LAN PC Anda, mis: http://192.168.1.10:8080
  final String baseUrl;

  ApiClient({String? overrideBaseUrl})
      : baseUrl = overrideBaseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8081';
    return 'http://10.0.2.2:8081';
  }

  String get socketUrl => baseUrl;


  Uri uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse(baseUrl).replace(
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query,
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
