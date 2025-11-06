import 'package:flutter/material.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/client.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing database connections and operations
class DatabaseService {
  static DatabaseService? _instance;
  PrismaClient? _prisma;
  bool _isInitialized = false;

  // Private constructor for singleton
  DatabaseService._();

  /// Get singleton instance
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Initialize the database connection
  Future<void> initialize({String? databaseName}) async {
    if (_isInitialized && _prisma != null) {
      AppLogger.warning('Database already initialized');
      return;
    }

    try {
      WidgetsFlutterBinding.ensureInitialized();

      final supportDir = await getApplicationSupportDirectory();
      final dbName = databaseName ?? 'dev.db';
      final database = join(supportDir.path, dbName);

      _prisma = PrismaClient(datasourceUrl: 'file:$database');
      
      await _prisma!.$connect();
      
      // Apply migrations if engine supports it
      try {
        final engine = _prisma!.$engine;
        if (engine.toString().contains('LibraryEngine')) {
          // Use dynamic call to avoid import issues
          await (engine as dynamic).applyMigrations(path: 'prisma/migrations');
        }
      } catch (e) {
        // Migrations might not be supported, continue anyway
        AppLogger.warning('Could not apply migrations', e);
      }

      _isInitialized = true;
      AppLogger.info('Database initialized successfully at: $database');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  /// Get the Prisma client instance
  PrismaClient get prisma {
    if (!_isInitialized || _prisma == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return _prisma!;
  }

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose and close the database connection
  Future<void> dispose() async {
    if (_prisma != null) {
      try {
        await _prisma!.$disconnect();
        AppLogger.info('Database connection closed');
      } catch (e) {
        AppLogger.error('Error closing database connection', e);
      }
      _prisma = null;
      _isInitialized = false;
    }
  }
}

