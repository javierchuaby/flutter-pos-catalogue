import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_dev_challenge/config/api_config.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';

class ApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<List<dynamic>> fetchProductsFromApi({int retryCount = 0}) async {
    try {
      AppLogger.info('Fetching products from API (attempt ${retryCount + 1})');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': ApiConfig.authorizationHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      AppLogger.debug('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        // API returns {"data": [...]} - extract the products array
        if (jsonResponse.containsKey('data')) {
          final productsData = jsonResponse['data'];
          if (productsData is List) {
            AppLogger.info('Successfully extracted ${productsData.length} products from API response');
            return productsData;
          } else {
            throw Exception('API data field is not a list: ${productsData.runtimeType}');
          }
        } else {
          throw Exception('API response missing "data" field or invalid format: $jsonResponse');
        }
      } else {
        // Provide more specific error messages
        String errorMsg;
        if (response.statusCode == 401) {
          errorMsg = 'Unauthorized: Invalid authentication token';
        } else if (response.statusCode == 404) {
          errorMsg = 'API endpoint not found';
        } else if (response.statusCode >= 500) {
          errorMsg = 'Server error (${response.statusCode}). The server may be temporarily unavailable.';
        } else if (response.statusCode == 522 || response.statusCode == 524) {
          errorMsg = 'Connection timeout. The server is taking too long to respond.';
        } else {
          final bodyPreview = response.body.isNotEmpty
              ? response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)
              : 'Unknown error';
          errorMsg = 'HTTP ${response.statusCode}: $bodyPreview';
        }
        AppLogger.error('API request failed', Exception(errorMsg));
        throw Exception(errorMsg);
      }
    } on TimeoutException catch (e) {
      AppLogger.warning('API fetch timeout (attempt ${retryCount + 1}): $e');
      // Retry on timeout if we haven't exceeded max retries
      if (retryCount < ApiConfig.maxRetries) {
        AppLogger.info('Retrying API request... (${retryCount + 1}/${ApiConfig.maxRetries})');
        await Future.delayed(Duration(seconds: 2)); // Wait before retry
        return fetchProductsFromApi(retryCount: retryCount + 1);
      }
      final errorMsg = 'Request timed out after ${ApiConfig.maxRetries + 1} attempts. The server is taking too long to respond. Please try again later.';
      AppLogger.error('API request timeout after retries', Exception(errorMsg));
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      AppLogger.error('API fetch network error', e);
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      AppLogger.error('API fetch error', e, stackTrace);
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
          'Authorization': ApiConfig.authorizationHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      AppLogger.debug('=== API DEBUG TEST ===');
      AppLogger.debug('Status: ${response.statusCode}');
      AppLogger.debug('Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        AppLogger.debug('Parsed: $decoded');
      }
      AppLogger.debug('=====================');
    } catch (e) {
      AppLogger.error('API Test Error', e);
    }
  }
}
