/// Application-wide constants
class AppConstants {
  // Connectivity monitoring
  static const Duration connectivityCheckInterval = Duration(seconds: 5);
  static const Duration connectivityCheckTimeout = Duration(seconds: 3);
  
  // UI constants
  static const double emptyStateHeightRatio = 0.7;
  static const double tabletBreakpoint = 600.0;
  
  // Grid layout
  static const int mobileGridColumns = 2;
  static const int tabletGridColumns = 3;
  static const double gridAspectRatio = 0.75;
  static const double gridSpacing = 16.0;
  
  // Auto-sync
  static const Duration autoSyncCooldown = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxDatabaseRetries = 3;
  static const Duration databaseRetryDelay = Duration(milliseconds: 500);
  
  // Private constructor to prevent instantiation
  AppConstants._();
}

/// Color constants for the app
class AppColors {
  static const int successGreen = 0xFF2E7D32;
  static const int errorRed = 0xFFD32F2F;
  static const int warningOrange = 0xFFF57C00;
  static const int infoBlue = 0xFF1976D2;
  
  // Private constructor to prevent instantiation
  AppColors._();
}

