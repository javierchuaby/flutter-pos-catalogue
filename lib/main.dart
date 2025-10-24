import 'package:flutter/material.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/client.dart';
import 'package:mobile_dev_challenge/_generated_prisma_client/model.dart';
import 'package:mobile_dev_challenge/db.dart';
import 'package:mobile_dev_challenge/services/api_service.dart';
import 'package:mobile_dev_challenge/utils/connectivity_service.dart';

late final PrismaClient prisma;

Future<void> main() async {
  await initPrismaClient();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordering Mobile Dev',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ordering Mobile Dev Challenge'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isInitialLoad = true;
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  String _statusMessage = 'Loading products...';

  @override
  void initState() {
    super.initState();
    _loadProductsFromDatabase();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await ConnectivityService.hasInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  Future<void> _loadProductsFromDatabase() async {
    try {
      final products = await fetchProducts();
      setState(() {
        _products = products;
        _isInitialLoad = false;
        _statusMessage = products.isEmpty
          ? 'No products found. Tap sync to fetch from server.'
          : 'Products loaded from local database (${products.length} items)';
      });
    } catch (e) {
      setState(() {
        _isInitialLoad = false;
        _statusMessage = 'Error loading products: $e';
      });
    }
  }

  Future<void> _syncProducts() async {
    // Check connectivity before attempting sync
    await _checkConnectivity();

    if (!_isOnline) {
      setState(() {
        _statusMessage = 'No internet connection. Showing cached products.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing products from server...';
    });

    try {
      // Fetch from API and save to database
      final apiProducts = await ApiService.fetchProductsFromApi();
      await createManyProducts(apiProducts);

      // Reload from database to refresh UI
      await _loadProductsFromDatabase();

      setState(() {
        _lastSyncTime = DateTime.now();
        _statusMessage = 'Products synced successfully! (${apiProducts.length} items)';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Sync failed: No internet connection. Showing cached products from last sync.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    size: 40,
                    color: Colors.orange[400],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Product Selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Product details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name', product.name),
                      const SizedBox(height: 8),
                      _buildDetailRow('Price', '\$${_formatPrice(product.price)}'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Product ID', '${product.id}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(String price) {
    final parsedPrice = double.tryParse(price);
    return parsedPrice?.toStringAsFixed(2) ?? price;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    if (!_isOnline) return Colors.orange[50]!;
    if (_statusMessage.contains('Error') || _statusMessage.contains('failed')) return Colors.red[50]!;
    if (_statusMessage.contains('successfully')) return Colors.green[50]!;
    return Colors.blue[50]!;
  }

  Color _getStatusTextColor() {
    if (!_isOnline) return Colors.orange[700]!;
    if (_statusMessage.contains('Error') || _statusMessage.contains('failed')) return Colors.red[700]!;
    if (_statusMessage.contains('successfully')) return Colors.green[700]!;
    return Colors.blue[700]!;
  }

  IconData _getStatusIcon() {
    if (!_isOnline) return Icons.wifi_off;
    if (_products.isNotEmpty) return Icons.storage;
    return Icons.cloud_sync;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_products.length} items',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getStatusIcon(),
                        size: 16,
                        color: _getStatusTextColor(),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _isOnline
                            ? _statusMessage
                            : 'Offline Mode - ${_products.length} products cached',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getStatusTextColor(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (_lastSyncTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last sync: ${_formatDateTime(_lastSyncTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Main content
            Expanded(
              child: _isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No products available',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the sync button to fetch products from server',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _showProductDialog(product),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product icon
                                  Container(
                                    width: double.infinity,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 32,
                                      color: Colors.orange[300],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Product name
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Price
                                  Text(
                                    '\$${_formatPrice(product.price)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Product ID
                                  Text(
                                    'ID: ${product.id}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _syncProducts,
        tooltip: 'Sync Products',
        backgroundColor: _isLoading ? Colors.grey : null,
        child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      ),
    );
  }
}
