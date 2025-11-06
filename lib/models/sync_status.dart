/// Enum representing the sync status of the application
enum SyncStatus {
  /// Initial loading state
  initial,
  
  /// Loading products from database
  loading,
  
  /// Successfully synced products
  success,
  
  /// Error occurred during sync
  error,
  
  /// Offline mode
  offline,
  
  /// Syncing in progress
  syncing,
}

/// Extension methods for SyncStatus
extension SyncStatusExtension on SyncStatus {
  /// Get user-friendly message for the status
  String getMessage({
    int? productCount,
    String? errorMessage,
  }) {
    switch (this) {
      case SyncStatus.initial:
        return 'Loading products...';
      case SyncStatus.loading:
        return 'Loading products from database...';
      case SyncStatus.success:
        return productCount != null
            ? 'Products synced successfully! ($productCount items)'
            : 'Products synced successfully!';
      case SyncStatus.error:
        return errorMessage ?? 'Sync failed. Please try again.';
      case SyncStatus.offline:
        return productCount != null
            ? 'Offline Mode - $productCount products cached'
            : 'Offline Mode';
      case SyncStatus.syncing:
        return 'Syncing products from server...';
    }
  }
  
  /// Get color for the status
  int get colorValue {
    switch (this) {
      case SyncStatus.initial:
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return 0xFFE3F2FD; // Light blue
      case SyncStatus.success:
        return 0xFFE8F5E9; // Light green
      case SyncStatus.error:
        return 0xFFFFEBEE; // Light red
      case SyncStatus.offline:
        return 0xFFFFF3E0; // Light orange
    }
  }
  
  /// Get text color for the status
  int get textColorValue {
    switch (this) {
      case SyncStatus.initial:
      case SyncStatus.loading:
      case SyncStatus.syncing:
        return 0xFF1976D2; // Blue
      case SyncStatus.success:
        return 0xFF2E7D32; // Green
      case SyncStatus.error:
        return 0xFFD32F2F; // Red
      case SyncStatus.offline:
        return 0xFFF57C00; // Orange
    }
  }
  
  /// Get icon for the status
  String get iconName {
    switch (this) {
      case SyncStatus.initial:
      case SyncStatus.loading:
        return 'cloud_sync';
      case SyncStatus.success:
        return 'check_circle';
      case SyncStatus.error:
        return 'error';
      case SyncStatus.offline:
        return 'wifi_off';
      case SyncStatus.syncing:
        return 'sync';
    }
  }
}

