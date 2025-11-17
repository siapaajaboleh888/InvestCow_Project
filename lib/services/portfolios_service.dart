import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';

class PortfoliosService {
  final _client = ApiClient();
  final _auth = AuthService();

  Future<List<Map<String, dynamic>>> list() async {
    final token = await _auth.getToken();
    final uri = _client.uri('/portfolios');
    final res = await http.get(uri, headers: _client.jsonHeaders(token: token));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat portofolio (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(String name) async {
    final token = await _auth.getToken();
    final uri = _client.uri('/portfolios');
    final res = await http.post(
      uri,
      headers: _client.jsonHeaders(token: token),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode != 201) {
      throw Exception('Gagal membuat portofolio (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrCreateDefault() async {
    final existing = await list();
    if (existing.isNotEmpty) {
      return existing.first;
    }
    return create('Portofolio Sapi Utama');
  }
}
