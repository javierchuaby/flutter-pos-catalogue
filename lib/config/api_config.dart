import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_dev_challenge/utils/logger.dart' as logger;

/// API configuration for the POS app
/// 
/// Loads configuration from environment variables (.env file)
/// Falls back to default values if environment variables are not set
class ApiConfig {
  // API endpoint - load from .env or use default
  static String get baseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url != null && url.isNotEmpty) {
      return url;
    }
    logger.AppLogger.warning('API_BASE_URL not found in .env, using default');
    return 'https://challenge-test.ordering.sg/api/products';
  }
  
  // Bearer token - load from .env or use default
  static String get bearerToken {
    final token = dotenv.env['API_BEARER_TOKEN'];
    if (token != null && token.isNotEmpty) {
      return token;
    }
    logger.AppLogger.warning('API_BEARER_TOKEN not found in .env, using default');
    return 'chicken-good'; // Fallback for development
  }
  
  // Get the full Authorization header value
  static String get authorizationHeader => 'Bearer $bearerToken';
  
  // Timeout duration for API calls (in seconds)
  // Increased to 60 seconds due to server response time
  static const int timeoutSeconds = 60;
  
  // Number of retry attempts for failed requests
  static const int maxRetries = 2;
  
  // Private constructor to prevent instantiation
  ApiConfig._();
}
