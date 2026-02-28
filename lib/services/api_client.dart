import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ApiClient {
  final String baseUrl;
  final http.Client _httpClient = http.Client();

  ApiClient({String? overrideBaseUrl})
      : baseUrl = overrideBaseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    const defineUrl = String.fromEnvironment('BASE_URL');
    if (defineUrl.isNotEmpty) return defineUrl;

    if (kReleaseMode) {
      return 'https://api.investcow.id'; 
    }

    if (kIsWeb) {
      return 'http://localhost:8081';
    } else {
      return 'http://192.168.1.111:8081'; 
    }
  }

  String get socketUrl => baseUrl;

  Uri uri(String path, [Map<String, dynamic>? query]) {
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

  // MANAGED REQUEST METHODS
  
  Future<http.Response> get(String path, {String? token, Map<String, dynamic>? query}) async {
    try {
      final url = uri(path, query);
      final response = await _httpClient.get(
        url,
        headers: jsonHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Server tidak merespon (Timeout). Periksa koneksi internet Anda.');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(String path, {String? token, dynamic body}) async {
    try {
      final url = uri(path);
      final response = await _httpClient.post(
        url,
        headers: jsonHeaders(token: token),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Koneksi terputus (Timeout).');
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> patch(String path, {String? token, dynamic body}) async {
    try {
      final url = uri(path);
      final response = await _httpClient.patch(
        url,
        headers: jsonHeaders(token: token),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> delete(String path, {String? token}) async {
    try {
      final url = uri(path);
      final response = await _httpClient.delete(
        url,
        headers: jsonHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      
      return _processResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  http.Response _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    
    // Extract error message from backend if available
    String? message;
    try {
      final data = jsonDecode(response.body);
      message = data['message'];
    } catch (_) {}
    
    throw Exception(message ?? 'Terjadi kesalahan sistem (${response.statusCode})');
  }
}
