import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/model.dart';
import 'package:mobile_dev_challenge/models/sync_status.dart';
import 'package:mobile_dev_challenge/repositories/product_repository.dart';
import 'package:mobile_dev_challenge/services/api_service.dart';
import 'package:mobile_dev_challenge/utils/connectivity_service.dart';
import 'package:mobile_dev_challenge/constants/app_constants.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider for managing product state and sync operations
class ProductProvider extends ChangeNotifier {
  final IProductRepository _repository;

  // State variables
  List<Product> _products = [];
  SyncStatus _status = SyncStatus.initial;
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  String? _errorMessage;
  Timer? _connectivityCheckTimer;
  DateTime? _lastAutoSyncAttempt;

  ProductProvider(this._repository) {
    _initialize();
  }

  // Getters
  List<Product> get products => _products;
  SyncStatus get status => _status;
  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  int get productCount => _products.length;
  bool get isLoading => _status == SyncStatus.loading || _status == SyncStatus.syncing;

  /// Initialize the provider
  Future<void> _initialize() async {
    await loadProductsFromDatabase();
    await checkConnectivity();
    _startConnectivityMonitoring();
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    ConnectivityService.initialize();
    
    // Also use periodic check as backup
    _connectivityCheckTimer = Timer.periodic(
      AppConstants.connectivityCheckInterval,
      (timer) async {
        final wasOffline = !_isOnline;
        await checkConnectivity();

        // Auto-sync when coming back online (with cooldown)
        if (wasOffline &&
            _isOnline &&
            !isLoading &&
            _products.isEmpty &&
            _canAutoSync()) {
          AppLogger.info('Auto-syncing products after coming back online');
          await syncProducts(showUserFeedback: false);
        }
      },
    );

    // Listen to connectivity stream
    ConnectivityService.onConnectivityChanged().listen((results) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection != _isOnline) {
        _isOnline = hasConnection;
        notifyListeners();
      }
    });
  }

  /// Check if auto-sync is allowed (cooldown period)
  bool _canAutoSync() {
    if (_lastAutoSyncAttempt == null) return true;
    final now = DateTime.now();
    final timeSinceLastAttempt = now.difference(_lastAutoSyncAttempt!);
    return timeSinceLastAttempt >= AppConstants.autoSyncCooldown;
  }

  /// Check connectivity status
  Future<void> checkConnectivity() async {
    try {
      final isOnline = await ConnectivityService.hasInternetConnection();
      if (_isOnline != isOnline) {
        _isOnline = isOnline;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.warning('Connectivity check failed', e);
    }
  }

  /// Load products from database
  Future<void> loadProductsFromDatabase() async {
    try {
      _status = SyncStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final products = await _repository.getProducts();
      _products = products;
      _status = products.isEmpty
          ? SyncStatus.initial
          : SyncStatus.success;
      _errorMessage = null;
      notifyListeners();

      AppLogger.info('Loaded ${products.length} products from database');
    } catch (e) {
      AppLogger.error('Failed to load products from database', e);
      _status = SyncStatus.error;
      _errorMessage = 'Error loading products: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Sync products from API
  Future<void> syncProducts({bool showUserFeedback = true}) async {
    // Check connectivity before attempting sync
    await checkConnectivity();

    if (!_isOnline) {
      _status = SyncStatus.offline;
      _errorMessage = 'No internet connection. Showing cached products.';
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    _errorMessage = null;
    if (showUserFeedback) {
      notifyListeners();
    }

    try {
      // Fetch from API
      final apiProducts = await ApiService.fetchProductsFromApi();

      // Convert to List<Map<String, dynamic>> for repository
      final productsList = apiProducts
          .map((product) => product as Map<String, dynamic>)
          .toList();

      // Save to database
      await _repository.saveProducts(productsList);

      // Reload from database
      await loadProductsFromDatabase();

      _lastSyncTime = DateTime.now();
      _lastAutoSyncAttempt = DateTime.now();
      _status = SyncStatus.success;
      _errorMessage = null;
      notifyListeners();

      AppLogger.info('Products synced successfully: ${apiProducts.length} items');
    } catch (e) {
      AppLogger.error('Failed to sync products', e);
      
      // Try to load from database as fallback
      try {
        await loadProductsFromDatabase();
      } catch (dbError) {
        AppLogger.error('Failed to load products from database as fallback', dbError);
      }

      _status = SyncStatus.error;
      final errorMessage = e.toString().toLowerCase();
      String userFriendlyMessage;

      if (errorMessage.contains('timeout') || errorMessage.contains('timed out')) {
        userFriendlyMessage = 'Connection timeout. The server may be slow. Please try again.';
      } else if (errorMessage.contains('server error') || errorMessage.contains('unavailable')) {
        userFriendlyMessage = 'Server temporarily unavailable. Please try again later.';
      } else if (errorMessage.contains('network error') || errorMessage.contains('connection')) {
        userFriendlyMessage = 'Network error. Please check your internet connection.';
      } else if (errorMessage.contains('unauthorized')) {
        userFriendlyMessage = 'Authentication failed. Please check API configuration.';
      } else {
        userFriendlyMessage = 'Sync failed: ${e.toString().replaceAll('Exception: ', '')}';
      }

      _errorMessage = userFriendlyMessage;
      notifyListeners();
    }
  }

  /// Handle refresh (pull-to-refresh)
  Future<void> handleRefresh() async {
    await syncProducts(showUserFeedback: true);
  }

  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    ConnectivityService.dispose();
    super.dispose();
  }
}

