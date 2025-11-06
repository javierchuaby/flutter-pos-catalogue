import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/model.dart';
import 'package:mobile_dev_challenge/providers/product_provider.dart';
import 'package:mobile_dev_challenge/repositories/product_repository.dart';
import 'package:mobile_dev_challenge/services/database_service.dart';
import 'package:mobile_dev_challenge/utils/price_formatter.dart';
import 'package:mobile_dev_challenge/widgets/product_card.dart';
import 'package:mobile_dev_challenge/widgets/product_dialog.dart';
import 'package:mobile_dev_challenge/widgets/status_banner.dart';
import 'package:mobile_dev_challenge/constants/app_constants.dart';
import 'package:mobile_dev_challenge/utils/logger.dart';
import 'package:mobile_dev_challenge/models/sync_status.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
      AppLogger.info('Environment variables loaded successfully');
  } catch (e) {
      AppLogger.warning('Failed to load .env file, using defaults', e);
  }

  // Initialize database
  try {
    await DatabaseService.instance.initialize();
      AppLogger.info('Database initialized successfully');
  } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize database', e, stackTrace);
    // Continue anyway - app might still work in some scenarios
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repository and provider
    final repository = ProductRepository(DatabaseService.instance);
    final productProvider = ProductProvider(repository);

    return ChangeNotifierProvider.value(
      value: productProvider,
      child: MaterialApp(
        title: 'Ordering Mobile Dev',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Ordering Mobile Dev Challenge'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.productCount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${provider.productCount} items',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Status banner
                StatusBanner(
                  status: provider.status,
                  isOnline: provider.isOnline,
                  errorMessage: provider.errorMessage,
                  lastSyncTime: provider.lastSyncTime,
                  productCount: provider.productCount,
                ),

                // Main content with pull-to-refresh
                Expanded(
                  child: _buildContent(context, provider),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton(
            onPressed: provider.isLoading ? null : () => provider.syncProducts(),
            tooltip: 'Sync Products',
            backgroundColor: provider.isLoading ? Colors.grey : null,
            child: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ProductProvider provider) {
    if (provider.status == SyncStatus.initial || provider.status == SyncStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.products.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * AppConstants.emptyStateHeightRatio,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to sync or tap the sync button',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.handleRefresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.gridSpacing),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > AppConstants.tabletBreakpoint
              ? AppConstants.tabletGridColumns
              : AppConstants.mobileGridColumns,
          crossAxisSpacing: AppConstants.gridSpacing,
          mainAxisSpacing: AppConstants.gridSpacing,
          childAspectRatio: AppConstants.gridAspectRatio,
        ),
        itemCount: provider.products.length,
        itemBuilder: (context, index) {
          final product = provider.products[index];
          return ProductCard(
            product: product,
            onTap: () => _showProductDialog(context, product),
            formatPrice: PriceFormatter.formatPrice,
          );
        },
      ),
    );
  }

  void _showProductDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProductDialog(
          product: product,
          formatPrice: PriceFormatter.formatPrice,
        );
      },
    );
  }
}
