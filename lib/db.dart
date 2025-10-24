import 'package:flutter/material.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/client.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/model.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/prisma.dart';
import 'package:mobile_dev_challenge/main.dart';
import 'package:orm/orm.dart';
import 'package:path/path.dart';
import 'package:orm_flutter/orm_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initPrismaClient() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final database = join(supportDir.path, 'dev.db');

  prisma = PrismaClient(datasourceUrl: 'file:$database');
  final engine = switch (prisma.$engine) {
    LibraryEngine engine => engine,
    _ => null,
  };

  await prisma.$connect();
  await engine?.applyMigrations(path: 'prisma/migrations');
}

/// Stores products in database, normalising price to String type
/// Expects: [{'id': int, 'name': string, 'price': string|number}]
Future<void> createManyProducts(dynamic products) async {
  try {
    await prisma.$transaction((prisma) async {
      // Clear existing products and insert new ones atomically
      await prisma.product.deleteMany();
      await prisma.product.createMany(
        data: PrismaUnion.$2(
          products.map<ProductCreateManyInput>((product) {
            // Normalize price to String
            final rawPrice = product['price'];
            final priceStr = rawPrice == null
              ? '0'
              : rawPrice is String
                ? rawPrice
                : rawPrice.toString();

            return ProductCreateManyInput(
              id: product['id'],
              name: product['name'],
              price: priceStr,
            );
          }).toList(),
        ),
      );
    });
    debugPrint('Successfully saved ${products.length} products to database');
  } catch (e) {
    debugPrint('Database save error: $e');
    throw Exception('Failed to save products: $e');
  }
}

Future<List<Product>> fetchProducts() async {
  try {
    final products = (await prisma.product.findMany()).toList();
    debugPrint('Loaded ${products.length} products from database');
    return products;
  } catch (e) {
    debugPrint('Database fetch error: $e');
    throw Exception('Failed to load products: $e');
  }
}

Future<int> getProductCount() async {
  try {
    final products = await prisma.product.findMany();
    return products.length;
  } catch (e) {
    debugPrint('Database count error: $e');
    return 0;
  }
}
