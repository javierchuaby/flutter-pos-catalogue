import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile_dev_challenge/constants/app_constants.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';
import 'dart:async';

/// Service for checking network connectivity
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isInitialized = false;

  /// Check if device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity()
          .timeout(AppConstants.connectivityCheckTimeout);
      
      final hasConnection = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
      
      AppLogger.debug('Connectivity check: ${hasConnection ? 'Online' : 'Offline'}');
      return hasConnection;
    } catch (e) {
      AppLogger.warning('Connectivity check failed', e);
      return false;
    }
  }

  /// Get current connectivity status
  static Future<List<ConnectivityResult>> getConnectivityStatus() async {
    try {
      return await _connectivity.checkConnectivity()
          .timeout(AppConstants.connectivityCheckTimeout);
    } catch (e) {
      AppLogger.warning('Failed to get connectivity status', e);
      return [ConnectivityResult.none];
    }
  }

  /// Listen to connectivity changes
  static Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged;
  }

  /// Initialize connectivity monitoring
  static void initialize() {
    if (_isInitialized) return;
    
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final hasConnection = results.any(
          (result) => result != ConnectivityResult.none,
        );
        AppLogger.info('Connectivity changed: ${hasConnection ? 'Online' : 'Offline'}');
      },
      onError: (error) {
        AppLogger.error('Connectivity stream error', error);
      },
    );
    
    _isInitialized = true;
    AppLogger.info('Connectivity monitoring initialized');
  }

  /// Dispose connectivity monitoring
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
    AppLogger.info('Connectivity monitoring disposed');
  }
}
