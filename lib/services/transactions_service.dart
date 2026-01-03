import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';

class TransactionsService {
  final _client = ApiClient();
  final _auth = AuthService();

  Future<List<Map<String, dynamic>>> listAll({
    int limit = 50,
    int offset = 0,
  }) async {
    final token = await _auth.getToken();
    final uri = _client.uri('/transactions/all', {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    final res = await http.get(uri, headers: _client.jsonHeaders(token: token));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat riwayat transaksi (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required int portfolioId,
    required String type,
    required String symbol,
    required double quantity,
    required double price,
    required DateTime occurredAt,
    String? note,
  }) async {
    final token = await _auth.getToken();
    final uri = _client.uri('/transactions');
    final body = {
      'portfolio_id': portfolioId,
      'type': type.toLowerCase(),
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'occurred_at': occurredAt.toIso8601String().substring(0, 19),
      'note': note,
    };
    final res = await http.post(
      uri,
      headers: _client.jsonHeaders(token: token),
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) {
      throw Exception('Gagal membuat transaksi (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  Future<List<Map<String, dynamic>>> getPortfolioSummary() async {
    final token = await _auth.getToken();
    final uri = _client.uri('/transactions/portfolio-summary');
    final res = await http.get(uri, headers: _client.jsonHeaders(token: token));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat ringkasan portofolio (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
