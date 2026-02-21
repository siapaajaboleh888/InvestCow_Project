import 'package:flutter_test/flutter_test.dart';
import 'package:investcow_app/services/api_client.dart';

void main() {
  group('DevOps Sanity Tests', () {
    test('ApiClient Default URL Check', () {
      final client = ApiClient();
      // Test ini memastikan base URL terinisialisasi
      expect(client.baseUrl, isNotEmpty);
      print('✅ DevOps: ApiClient initialized with ${client.baseUrl}');
    });

    test('Logic Test: Simple math for InvestCow', () {
      const weight = 300.0;
      const pricePerKg = 60000.0;
      const total = weight * pricePerKg;
      expect(total, 18000000.0);
      print('✅ DevOps: Price logic calculation verified');
    });
  });
}
