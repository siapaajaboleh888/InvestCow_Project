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
    final res = await _client.get('/transactions/all', token: token, query: {
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    
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
    final body = {
      'portfolio_id': portfolioId,
      'type': type.toLowerCase(),
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
      'occurred_at': occurredAt.toIso8601String().substring(0, 19),
      'note': note,
    };
    
    final res = await _client.post('/transactions', token: token, body: body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getPortfolioSummary() async {
    final token = await _auth.getToken();
    final res = await _client.get('/transactions/portfolio-summary', token: token);
    
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
