import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // For clearing auth token
import 'landing_screen.dart'; // Import your landing page
void main() {
  runApp(const MaterialApp(
    home: ResellerDashboard(token: ""),
    debugShowCheckedModeBanner: false,
  ));
}

class Product {
  String id;
  String name;
  double price;
  String? imageUrl;

  Product({required this.id, required this.name, required this.price, this.imageUrl});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }
}

class Order {
  String id;
  String customerId;
  String productId;
  String productName;
  String? productImage;
  int quantity;
  double totalPrice;
  String status;
  String shippingAddress;
  
  // For displaying customer info
  String customerName;

  Order({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.shippingAddress,
    required this.customerName, // This must be non-null to prevent the error
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Extract or provide default values for required fields
    String customerNameValue = 'Unknown Customer';
    
    // Try to get customer name from populated customerId
    if (json['customerId'] is Map) {
      customerNameValue = json['customerId']['email'] ?? customerNameValue;
    }
    
    return Order(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: json['customerId'] is String 
          ? json['customerId'] 
          : (json['customerId'] is Map ? json['customerId']['_id']?.toString() ?? '' : ''),
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Unknown Product',
      productImage: json['productImage']?.toString(),
      quantity: json['quantity'] is int ? json['quantity'] : 1,
      totalPrice: json['totalPrice'] is num 
          ? json['totalPrice'].toDouble() 
          : (double.tryParse(json['totalPrice']?.toString() ?? '0') ?? 0.0),
      status: json['status']?.toString() ?? 'pending',
      shippingAddress: json['shippingAddress']?.toString() ?? json['address']?.toString() ?? 'No address',
      customerName: customerNameValue, // Always provide a non-null value
    );
  }
}

class ResellerDashboard extends StatefulWidget {
  final String token;
  const ResellerDashboard({Key? key, required this.token}) : super(key: key);

  @override
  State<ResellerDashboard> createState() => _ResellerDashboardState();
}

class _ResellerDashboardState extends State<ResellerDashboard> {
  int _selectedTab = 0;
  List<Product> products = [];
  List<Order> orders = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String baseUrl = "http://localhost:5000/api";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchOrders();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/products"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        throw Exception("Failed to load products");
      }
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  Future<void> _fetchOrders() async {
  try {
    // Use the seller-orders endpoint
    final response = await http.get(
      Uri.parse("$baseUrl/orders/seller-orders"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    
    print("Orders response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print("Fetched ${data.length} orders");
      
      setState(() {
        orders = data.map((json) => Order.fromJson(json)).toList();
      });
    } else {
      // Fallback to the old endpoint
      final fallbackResponse = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      
      if (fallbackResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(fallbackResponse.body);
        setState(() {
          orders = data.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception("Failed to load orders: ${response.statusCode}");
      }
    }
  } catch (e) {
    print("Error fetching orders: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load orders: $e")),
    );
  }
}


  Future<void> _addProduct(String name, double price, String? imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/products"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "price": price,
          "imageUrl": imageUrl,
        }),
      );
      if (response.statusCode == 201) {
        _fetchProducts();
      } else {
        throw Exception("Failed to add product");
      }
    } catch (e) {
      print("Error adding product: $e");
    }
  }

  Future<void> _editProduct(String id, String name, double price, String? imageUrl) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/products/$id"),
        headers: {
          "Authorization": "Bearer ${widget.token}",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": name,
          "price": price,
          "imageUrl": imageUrl,
        }),
      );
      if (response.statusCode == 200) {
        _fetchProducts();
      } else {
        throw Exception("Failed to edit product");
      }
    } catch (e) {
      print("Error editing product: $e");
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/products/$id"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        _fetchProducts();
      } else {
        throw Exception("Failed to delete product");
      }
    } catch (e) {
      print("Error deleting product: $e");
    }
  }

  void _showAddProductDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: imageUrlController, decoration: const InputDecoration(labelText: "Image URL")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text;
              final price = double.tryParse(priceController.text) ?? 0.0;
              final imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
              _addProduct(name, price, imageUrl);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _showAddProductDialog,
          icon: const Icon(Icons.add),
          label: const Text("Add Product"),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, i) => ListTile(
              leading: (products[i].imageUrl != null && products[i].imageUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        products[i].imageUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
              title: Text(products[i].name),
              subtitle: Text("\$${products[i].price.toStringAsFixed(2)}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      TextEditingController nameController = TextEditingController(text: products[i].name);
                      TextEditingController priceController = TextEditingController(text: products[i].price.toString());
                      TextEditingController imageUrlController = TextEditingController(text: products[i].imageUrl ?? '');

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Edit Product"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: "Name"),
                              ),
                              TextField(
                                controller: priceController,
                                decoration: const InputDecoration(labelText: "Price"),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: imageUrlController,
                                decoration: const InputDecoration(labelText: "Image URL"),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final updatedName = nameController.text;
                                final updatedPrice = double.tryParse(priceController.text) ?? 0.0;
                                final updatedImageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;

                                _editProduct(products[i].id, updatedName, updatedPrice, updatedImageUrl);
                                Navigator.pop(context);
                              },
                              child: const Text("Save"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteProduct(products[i].id);
                    },
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildOrdersTab() {
  if (orders.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No orders yet"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchOrders,
            child: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  return ListView.builder(
    itemCount: orders.length,
    itemBuilder: (_, i) => Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: orders[i].productImage != null && orders[i].productImage!.isNotEmpty
            ? Image.network(
                orders[i].productImage!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.shopping_cart),
              )
            : const Icon(Icons.shopping_cart),
        title: Text(orders[i].productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${orders[i].customerName}"),
            Text("Status: ${orders[i].status}")
          ],
        ),
        isThreeLine: true,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Order Details"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Product: ${orders[i].productName}"),
                  Text("Customer: ${orders[i].customerName}"),
                  Text("Quantity: ${orders[i].quantity}"),
                  Text("Price: \$${orders[i].totalPrice.toStringAsFixed(2)}"),
                  Text("Status: ${orders[i].status}"),
                  const Divider(),
                  const Text("Shipping Address:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(orders[i].shippingAddress),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
                // Add buttons to update order status
                if (orders[i].status == 'pending')
                  ElevatedButton(
                    onPressed: () {
                      // Implement status update
                      _updateOrderStatus(orders[i].id, 'processing');
                      Navigator.pop(context);
                    },
                    child: const Text("Process Order"),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}


// Add status badge helper
Widget _buildStatusBadge(String status) {
  Color color;
  switch (status.toLowerCase()) {
    case 'pending': color = Colors.orange; break;
    case 'processing': color = Colors.blue; break;
    case 'shipped': color = Colors.indigo; break;
    case 'delivered': color = Colors.green; break;
    case 'cancelled': color = Colors.red; break;
    default: color = Colors.grey;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      _capitalizeFirstLetter(status),
      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
    ),
  );
}

String _capitalizeFirstLetter(String text) {
  if (text.isEmpty) return '';
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

// Method to show detailed order information
void _showOrderDetails(Order order) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Order Details"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Product: ${order.productName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Customer: ${order.customerName ?? 'Customer'}"),
            Text("Status: ${order.status}"),
            Text("Quantity: ${order.quantity}"),
            Text("Total Price: \$${order.totalPrice.toStringAsFixed(2)}"),
            const Divider(),
            const Text("Shipping Address:", style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order.shippingAddress),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        if (order.status == 'pending') 
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order.id, 'processing');
            },
            child: const Text("Process Order"),
          ),
        if (order.status == 'processing')
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus(order.id, 'shipped');
            },
            child: const Text("Mark Shipped"),
          ),
      ],
    ),
  );
}
// Add method to update order status
Future<void> _updateOrderStatus(String orderId, String status) async {
  try {
    final response = await http.put(
      Uri.parse("$baseUrl/orders/$orderId/status"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
      body: json.encode({"status": status}),
    );
    
    if (response.statusCode == 200) {
      _fetchOrders(); // Refresh orders
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order status updated to $status")),
      );
    } else {
      throw Exception("Failed to update order status");
    }
  } catch (e) {
    print("Error updating order status: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update order status")),
    );
  }
}
  void _logout() async {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirm Logout"),
      content: const Text("Are you sure you want to log out?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancel")
        ),
        ElevatedButton(
          onPressed: () async {
            // Close the dialog
            Navigator.pop(context);
            
            try {
              // Clear the auth token from SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              
              if (context.mounted) {
                // Navigate to landing page and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LandingScreen(onToggleTheme: () {}),
                  ),
                  (route) => false, // This removes all previous routes
                );
              }
            } catch (e) {
              print("Error during logout: $e");
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error logging out")),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Logout"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Reseller Dashboard"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("Menu", style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Products"),
              selected: _selectedTab == 0,
              onTap: () {
                setState(() => _selectedTab = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text("Orders"),
              selected: _selectedTab == 1,
              onTap: () {
                setState(() => _selectedTab = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _selectedTab == 0 ? _buildProductsTab() : _buildOrdersTab(),
      ),
    );
  }
}
