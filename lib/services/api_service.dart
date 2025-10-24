import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://challenge-test.ordering.sg/api/products';
  static const String _bearerToken = 'Bearer chicken-good';

  static Future<List<dynamic>> fetchProductsFromApi() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': _bearerToken,
          'Content-Type': 'application/json',
        },
      );

      debugPrint('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // API returns {"data": [...]} - extract the products array
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
          final productsData = jsonResponse['data'];
          if (productsData is List) {
            debugPrint('Successfully extracted ${productsData.length} products from API response');
            return productsData;
          } else {
            throw Exception('API data field is not a list: ${productsData.runtimeType}');
          }
        } else {
          throw Exception('API response missing "data" field or invalid format: $jsonResponse');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('API fetch error: $e');
      rethrow; // Re-throw for proper error handling upstream
    }
  }

  // Debug helper
  static Future<void> testApiResponse() async {
    if (!kDebugMode) return;

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': _bearerToken,
          'Content-Type': 'application/json',
        },
      );

      debugPrint('=== API DEBUG TEST ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        debugPrint('Parsed: $decoded');
      }
      debugPrint('=====================');
    } catch (e) {
      debugPrint('API Test Error: $e');
    }
  }
}
