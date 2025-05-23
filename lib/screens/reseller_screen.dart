import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  String customerName;
  String productName;
  String? address;
  String? size;

  Order({
    required this.customerName,
    required this.productName,
    this.address,
    this.size,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      customerName: json['customerName'],
      productName: json['productName'],
      address: json['address'],
      size: json['size'],
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
      final response = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data.map((json) => Order.fromJson(json)).toList();
        });
      } else {
        throw Exception("Failed to load orders");
      }
    } catch (e) {
      print("Error fetching orders: $e");
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
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: Text(orders[i].productName),
        subtitle: Text("Ordered by ${orders[i].customerName}"),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Order Details"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer: ${orders[i].customerName}"),
                  Text("Product: ${orders[i].productName}"),
                  Text("Size: ${orders[i].size}"),
                  Text("Address: ${orders[i].address}"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
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
