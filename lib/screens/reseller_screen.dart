import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: ResellerDashboard(),
    debugShowCheckedModeBanner: false,
  ));
}

class Product {
  String name;
  double price;
  String? imageUrl;

  Product({required this.name, required this.price, this.imageUrl});
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
}

class ResellerDashboard extends StatefulWidget {
  const ResellerDashboard({super.key});

  @override
  State<ResellerDashboard> createState() => _ResellerDashboardState();
}

class _ResellerDashboardState extends State<ResellerDashboard> {
  int _selectedTab = 0;

  List<Product> products = [
    Product(name: "Blue Shirt", price: 19.99, imageUrl: ""),
    Product(name: "Red Sneakers", price: 39.99, imageUrl: null),
  ];

  List<Order> orders = [
    Order(
      customerName: "Alice",
      productName: "Blue Shirt",
      address: "123 Main St, Springfield",
      size: "M",
    ),
    Order(
      customerName: "Bob",
      productName: "Red Sneakers",
      address: "456 Oak Ave, Riverdale",
      size: "10",
    ),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _addProduct() {
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
              setState(() {
                products.add(Product(
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                ));
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _editProduct(int index) {
    TextEditingController nameController = TextEditingController(text: products[index].name);
    TextEditingController priceController = TextEditingController(text: products[index].price.toString());
    TextEditingController imageUrlController = TextEditingController(text: products[index].imageUrl ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Product"),
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
              setState(() {
                products[index].name = nameController.text;
                products[index].price = double.tryParse(priceController.text) ?? products[index].price;
                products[index].imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _deleteProduct(int index) {
    setState(() {
      products.removeAt(index);
    });
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _addProduct,
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
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _editProduct(i)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteProduct(i)),
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
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to login screen
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