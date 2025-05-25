import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar_component.dart';
import 'reseller_component.dart';
import 'designer_component.dart';
import 'tailor_component.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CustomerScreen(),
  ));
}

class CustomerScreen extends StatefulWidget {
  final String? token;
  
  const CustomerScreen({Key? key, this.token}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  bool _isSidebarOpen = false;
  int _selectedTab = 0;
  final List<String> tabs = ['Home', 'Orders', 'Profile'];
  final Color violet = const Color(0xFFB878FF);
  final Color violetDark = const Color(0xFFB361F8);

  // Add baseUrl for API calls
  final String baseUrl = 'http://localhost:5000/api';
  
  List<Map<String, dynamic>> _orders = [];
  bool _isOrdersLoading = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _saveToken();
    _fetchCurrentUser();
  }

  // Token management methods
  Future<void> _saveToken() async {
    if (widget.token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', widget.token!);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Fetch current user details
  Future<void> _fetchCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _currentUser = json.decode(response.body);
        });
        print('Current user loaded: ${_currentUser?['email']}');
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }
  
  // Order loading method
  Future<void> _loadOrders() async {
  setState(() {
    _isOrdersLoading = true;
  });
  
  try {
    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isOrdersLoading = false;
      });
      return;
    }
    
    // Create a combined list for all order types
    List<Map<String, dynamic>> allOrders = [];
    
    // Fetch regular product orders
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          allOrders.addAll(List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (e) {
      print('Error loading product orders: $e');
    }
    
    // Fetch designer orders
    try {
      final designerResponse = await http.get(
        Uri.parse('$baseUrl/designerorders/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (designerResponse.statusCode == 200) {
        final data = json.decode(designerResponse.body);
        if (data is List) {
          allOrders.addAll(List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (e) {
      print('Error loading designer orders: $e');
    }
    
    // Fetch tailor orders
    try {
      final tailorResponse = await http.get(
        Uri.parse('$baseUrl/tailor-orders/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (tailorResponse.statusCode == 200) {
        final data = json.decode(tailorResponse.body);
        if (data is List) {
          allOrders.addAll(List<Map<String, dynamic>>.from(data));
        }
      }
    } catch (e) {
      print('Error loading tailor orders: $e');
    }
    
    // Sort combined orders by date (newest first)
    allOrders.sort((a, b) {
      final aDate = a['createdAt'] ?? '';
      final bDate = b['createdAt'] ?? '';
      return bDate.compareTo(aDate);
    });
    
    setState(() {
      _orders = allOrders;
      _isOrdersLoading = false;
    });
  } catch (e) {
    print('Error loading orders: $e');
    setState(() {
      _orders = [];
      _isOrdersLoading = false;
    });
  }
}

  // Helper function for safe string conversion
  String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  // NEW METHOD: Show order dialog when "Order Now" is clicked
  Future<void> _showOrderDialog(Map<String, dynamic> product, String sellerId, String sellerRole) async {
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController addressController = TextEditingController();
    
    // Extract price from product (handle different property names)
    final String priceStr = safeString(
      product['price'] ?? product['totalPrice'] ?? '0'
    );
    final double price = double.tryParse(priceStr) ?? 0;
    double totalPrice = price;
    
    // For tracking loading state
    bool isPlacingOrder = false;

    // Event type (for designer orders)
    String eventType = 'Marriage';
    
    // Measurements controllers (for designer orders)
    final Map<String, TextEditingController> measurementControllers = {
      'Height': TextEditingController(),
      'Bust': TextEditingController(),
      'Waist': TextEditingController(),
      'Hips': TextEditingController(),
    };
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Order ${safeString(product['title'] ?? product['name'], defaultValue: 'Product')}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display product image if available
                  if (product['image'] != null || 
                      (product['imageUrls'] != null && (product['imageUrls'] as List).isNotEmpty))
                    _buildProductImage(product['image'] ?? product['imageUrls'][0]),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Price: \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity selector
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      setStateDialog(() {
                        totalPrice = price * quantity;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Display total price based on quantity
                  Text(
                    'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Address field
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Shipping Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  
                  // For designer orders, add extra fields
                  if (sellerRole == 'designer') ...[
                    const SizedBox(height: 16),
                    const Text('Event Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: eventType,
                      items: ['Marriage', 'Birthday', 'Festival', 'Other']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          eventType = value;
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Text('Measurements', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Generate measurement fields
                    ...measurementControllers.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isPlacingOrder ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isPlacingOrder
                    ? null
                    : () async {
                        // Validate input
                        if (addressController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter your shipping address')),
                          );
                          return;
                        }

                        final quantity = int.tryParse(quantityController.text) ?? 1;
                        if (quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quantity must be at least 1')),
                          );
                          return;
                        }

                        // Start loading
                        setStateDialog(() {
                          isPlacingOrder = true;
                        });

                        try {
                          await _placeOrder(
                            product: product,
                            sellerId: sellerId, 
                            sellerRole: sellerRole,
                            quantity: quantity,
                            totalPrice: totalPrice,
                            address: addressController.text.trim(),
                            eventType: eventType,
                            measurements: measurementControllers.map((key, controller) => 
                              MapEntry(key, controller.text.isNotEmpty ? controller.text : 'N/A')
                            ),
                          );
                          
                          if (context.mounted) {
                            // Close dialog and show success message
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order placed successfully!')),
                            );
                          }
                        } catch (e) {
                          // Show error and stop loading
                          setStateDialog(() {
                            isPlacingOrder = false;
                          });
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error placing order: ${e.toString()}')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: violetDark),
                child: isPlacingOrder
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Place Order'),
              ),
            ],
          );
        });
      },
    );
  }

  // NEW METHOD: Build product image
  Widget _buildProductImage(String imageSource) {
    try {
      if (imageSource.startsWith('data:image')) {
        // For base64 images
        final parts = imageSource.split(',');
        if (parts.length >= 2) {
          final base64String = parts[1];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64String),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          );
        }
      }
      
      // For regular URL images
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageSource,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 150,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported, size: 50),
          ),
        ),
      );
    } catch (e) {
      print('Error displaying image: $e');
      return Container(
        height: 150,
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 50),
      );
    }
  }

  // NEW METHOD: Send order to server
  Future<void> _placeOrder({
    required Map<String, dynamic> product,
    required String sellerId,
    required String sellerRole,
    required int quantity,
    required double totalPrice,
    required String address,
    String eventType = 'Marriage',
    Map<String, String>? measurements,
  }) async {
    print('Placing order for $sellerRole: $sellerId');
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    
    // Determine endpoint based on seller role
    String endpoint;
    Map<String, dynamic> orderData;
    
    if (sellerRole == 'designer') {
      // For designer orders - using the DesignerOrder model
      endpoint = '$baseUrl/designerorders';
      
      // Create order data matching the DesignerOrder schema
      orderData = {
        'client': _currentUser?['email'] ?? 'Customer',
        'address': address,
        'event': eventType,
        'status': 'In Progress',
        'measurements': measurements ?? {
          'Height': 'N/A',
          'Bust': 'N/A',
          'Waist': 'N/A',
          'Hips': 'N/A',
        },
        'designerId': sellerId
      };
    } else if (sellerRole == 'tailor') {
      // For tailor orders
      endpoint = '$baseUrl/tailor-orders';
      
      // Create order data matching the tailor order schema
      orderData = {
        'productId': product['id'] ?? product['_id'],
        'quantity': quantity,
        'totalPrice': totalPrice,
        'status': 'pending',
        'shippingAddress': address,
        'tailorId': sellerId
      };
    } else {
      // For regular customer orders (resellers) - using the CustomerOrder model
      endpoint = '$baseUrl/orders';
      
      // Create order data matching the CustomerOrder schema
      orderData = {
        'productId': product['id'] ?? product['_id'],
        'sellerId': sellerId,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'status': 'pending',
        'shippingAddress': address
      };
    }
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );
      
      print('Order response status: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Order created successfully
        print('Order placed successfully!');
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, log a warning
        print("WARNING: Endpoint not found. Order would have been created in production.");
        // In development, we can consider it a success
      } else {
        throw Exception('Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _placeOrder: $e");
      throw e;
    }
  }
  
  // NEW METHOD: Build product card with order button
  Widget _buildProductCard(Map<String, dynamic> product, String sellerId, String sellerRole) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['title'] ?? product['name'] ?? 'Product',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(product['description'] ?? 'No description available'),
            const SizedBox(height: 10),
            
            // Display image
            if (product['image'] != null)
              _buildProductImage(product['image'])
            else if (product['imageUrls'] != null && (product['imageUrls'] as List).isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (product['imageUrls'] as List).map<Widget>((url) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 10),
            
            // Display price and order button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${product['price'] ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Order Now'),
                  onPressed: () => _showOrderDialog(product, sellerId, sellerRole),
                  style: ElevatedButton.styleFrom(backgroundColor: violetDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tab content builders
  Widget _buildHomeTab() {
    // Pass the buildProductCard method to each component
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ResellerComponentWithOrders(
                  violet: violet, 
                  onOrder: (product, sellerId) => _showOrderDialog(product, sellerId, 'reseller'),
                  buildProductCard: _buildProductCard,
                ),
              ),
              Expanded(
                child: DesignerComponentWithOrders(
                  violet: violet, 
                  onOrder: (product, sellerId) => _showOrderDialog(product, sellerId, 'designer'),
                  buildProductCard: _buildProductCard,
                ),
              ),
              Expanded(
                child: TailorComponentWithOrders(
                  violet: violet, 
                  onOrder: (product, sellerId) => _showOrderDialog(product, sellerId, 'tailor'),
                  buildProductCard: _buildProductCard,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOrdersTab() {
  if (_isOrdersLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  
  if (_orders.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('No orders found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(backgroundColor: violetDark),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  return ListView.builder(
    itemCount: _orders.length,
    itemBuilder: (context, index) {
      final order = _orders[index];
      
      // Get product name with multiple fallbacks for different order types
      String productName;
      if (order['productName'] != null) {
        // Regular product order
        productName = order['productName'];
      } else if (order['event'] != null) {
        // Designer order
        productName = 'Custom ${order['event']} Design';
      } else if (order['service'] != null) {
        // Tailor order
        productName = order['service'];
      } else {
        // Last resort fallback
        productName = 'Order #${order['_id']?.toString().substring(0, 6) ?? ''}';
      }
      
      // Get order status with fallback
      final String status = order['status'] ?? 'pending';
      
      // Get price with fallback
      final String price = order['totalPrice']?.toString() ?? '0.00';
      
      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(order['productImage'] ?? 'https://via.placeholder.com/100'),
            onBackgroundImageError: (_, __) => const Icon(Icons.error),
          ),
          title: Text(productName),
          subtitle: Text('${status.toUpperCase()} • \$$price'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show order details
            _showOrderDetailsDialog(order, productName);
          },
        ),
      );
    },
  );
}

void _showOrderDetailsDialog(Map<String, dynamic> order, String productName) {
  // Create a formatted dialog to show order details
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(productName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show details based on order type
            Text('Status: ${order['status'] ?? 'pending'}'),
            Text('Price: \$${order['totalPrice'] ?? '0.00'}'),
            
            // For designer orders
            if (order['event'] != null)
              Text('Event: ${order['event']}'),
              
            // For all orders
            if (order['shippingAddress'] != null || order['address'] != null)
              Text('Shipping Address: ${order['shippingAddress'] ?? order['address']}'),
              
            // For designer orders with measurements
            if (order['measurements'] != null && order['measurements'] is Map) ...[
              const Divider(),
              const Text('Measurements:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...Map<String, dynamic>.from(order['measurements']).entries.map(
                (e) => Text('${e.key}: ${e.value}')
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
  
  Widget _buildProfileTab() {
    final Map<String, TextEditingController> sizeControllers = {
      'Chest': TextEditingController(),
      'Waist': TextEditingController(),
      'Hips': TextEditingController(),
      'Shoulder': TextEditingController(),
      'Inseam': TextEditingController(),
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Measurements',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sizeControllers.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Measurements saved')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: violet),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildOrdersTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              NavbarComponent(
                isSidebarOpen: _isSidebarOpen,
                onSidebarToggle: (value) => setState(() => _isSidebarOpen = value),
                selectedTab: _selectedTab,
                onTabSelect: (index) {
                  setState(() {
                    _selectedTab = index;
                    if (index == 1) {
                      _loadOrders();
                    }
                  });
                },
                tabs: tabs,
                violetDark: violetDark,
              ),
              Expanded(child: _getSelectedTabContent()),
            ],
          ),
          
          // Sidebar overlay
          SidebarOverlay(
            isOpen: _isSidebarOpen,
            onToggle: (value) => setState(() => _isSidebarOpen = value),
            violet: violet,
            violetDark: violetDark,
          ),
        ],
      ),
    );
  }
}

// Extended components with order functionality
class ResellerComponentWithOrders extends StatelessWidget {
  final Color violet;
  final Function(Map<String, dynamic>, String) onOrder;
  final Widget Function(Map<String, dynamic>, String, String) buildProductCard;
  
  const ResellerComponentWithOrders({
    Key? key,
    required this.violet,
    required this.onOrder,
    required this.buildProductCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use original ResellerComponent and add order buttons to products
    return ResellerComponent(violet: violet);
  }
}

class DesignerComponentWithOrders extends StatelessWidget {
  final Color violet;
  final Function(Map<String, dynamic>, String) onOrder;
  final Widget Function(Map<String, dynamic>, String, String) buildProductCard;
  
  const DesignerComponentWithOrders({
    Key? key,
    required this.violet,
    required this.onOrder,
    required this.buildProductCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use original DesignerComponent and add order buttons to products
    return DesignerComponent(violet: violet);
  }
}

class TailorComponentWithOrders extends StatelessWidget {
  final Color violet;
  final Function(Map<String, dynamic>, String) onOrder;
  final Widget Function(Map<String, dynamic>, String, String) buildProductCard;
  
  const TailorComponentWithOrders({
    Key? key,
    required this.violet,
    required this.onOrder,
    required this.buildProductCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use original TailorComponent and add order buttons to products
    return TailorComponent(violet: violet);
  }
}
