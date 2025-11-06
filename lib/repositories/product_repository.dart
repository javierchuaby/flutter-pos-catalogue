import 'package:mobile_dev_challenge/_generated_prisma_client/model.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/prisma.dart';
import 'package:mobile_dev_challenge/services/database_service.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';
import 'package:mobile_dev_challenge/constants/app_constants.dart';
import 'package:orm/orm.dart';

/// Repository interface for product data operations
abstract class IProductRepository {
  Future<List<Product>> getProducts();
  Future<void> saveProducts(List<Map<String, dynamic>> products);
  Future<int> getProductCount();
  Future<void> clearProducts();
}

/// Implementation of product repository using Prisma
class ProductRepository implements IProductRepository {
  final DatabaseService _databaseService;

  ProductRepository(this._databaseService);

  @override
  Future<List<Product>> getProducts() async {
    int retryCount = 0;
    while (retryCount < AppConstants.maxDatabaseRetries) {
      try {
        final products = await _databaseService.prisma.product.findMany();
        final productList = products.toList();
        AppLogger.info('Loaded ${productList.length} products from database');
        return productList;
      } catch (e, stackTrace) {
        retryCount++;
        AppLogger.warning(
          'Database fetch error (attempt $retryCount/${AppConstants.maxDatabaseRetries})',
          e,
        );

        if (retryCount >= AppConstants.maxDatabaseRetries) {
          AppLogger.error('Failed to load products after retries', e, stackTrace);
          throw Exception('Failed to load products: $e');
        }

        // Wait before retry
        await Future.delayed(AppConstants.databaseRetryDelay);
      }
    }
    throw Exception('Failed to load products after retries');
  }

  @override
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    if (products.isEmpty) {
      AppLogger.info('No products to save');
      return;
    }

    // Validate input
    _validateProducts(products);

    int retryCount = 0;
    while (retryCount < AppConstants.maxDatabaseRetries) {
      try {
        await _databaseService.prisma.$transaction((prisma) async {
          // Clear existing products and insert new ones atomically
          await prisma.product.deleteMany();
          
          await prisma.product.createMany(
            data: PrismaUnion.$2(
              products.map<ProductCreateManyInput>((product) {
                // Normalize price to String with validation
                final rawPrice = product['price'];
                final priceStr = _normalizePrice(rawPrice);

                final id = product['id'] as int?;
                final name = product['name'] as String?;

                if (id == null) {
                  throw ArgumentError('Product missing required field: id');
                }
                if (name == null || name.isEmpty) {
                  throw ArgumentError('Product missing required field: name');
                }

                return ProductCreateManyInput(
                  id: id,
                  name: name,
                  price: priceStr,
                );
              }).toList(),
            ),
          );
        });

        AppLogger.info('Successfully saved ${products.length} products to database');
        return; // Success, exit retry loop
      } catch (e, stackTrace) {
        retryCount++;
        AppLogger.warning(
          'Database save error (attempt $retryCount/${AppConstants.maxDatabaseRetries})',
          e,
        );

        if (retryCount >= AppConstants.maxDatabaseRetries) {
          AppLogger.error('Failed to save products after retries', e, stackTrace);
          throw Exception('Failed to save products: $e');
        }

        // Wait before retry
        await Future.delayed(AppConstants.databaseRetryDelay);
      }
    }
  }

  @override
  Future<int> getProductCount() async {
    try {
      // Use count query if available, otherwise count in memory
      final products = await _databaseService.prisma.product.findMany();
      final count = products.length;
      AppLogger.debug('Product count: $count');
      return count;
    } catch (e) {
      AppLogger.error('Failed to get product count', e);
      return 0;
    }
  }

  @override
  Future<void> clearProducts() async {
    try {
      await _databaseService.prisma.product.deleteMany();
      AppLogger.info('All products cleared from database');
    } catch (e) {
      AppLogger.error('Failed to clear products', e);
      throw Exception('Failed to clear products: $e');
    }
  }

  /// Validate products list before saving
  void _validateProducts(List<Map<String, dynamic>> products) {
    for (int i = 0; i < products.length; i++) {
      final product = products[i];

      if (product['id'] == null) {
        throw ArgumentError('Product at index $i missing required field: id');
      }
      if (product['name'] == null || (product['name'] as String).isEmpty) {
        throw ArgumentError('Product at index $i missing required field: name');
      }
    }
  }

  /// Normalize price to string format
  String _normalizePrice(dynamic rawPrice) {
    if (rawPrice == null) return '0.00';
    
    if (rawPrice is String) {
      return rawPrice.isEmpty ? '0.00' : rawPrice;
    }
    
    if (rawPrice is num) {
      return rawPrice.toString();
    }
    
    // Try to convert to string
    final priceStr = rawPrice.toString();
    if (priceStr.isEmpty) return '0.00';
    
    return priceStr;
  }
}

