import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'navbar_component.dart';
import 'reseller_component.dart';
import 'designer_component.dart';
import 'tailor_component.dart';
// Also need to keep or move RoleDetailPage and ChatScreen classes

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

  List<Map<String, dynamic>> _orders = [];
  bool _isOrdersLoading = false;

  @override
  void initState() {
    super.initState();
    _saveToken();
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
  
  // Order loading method
  Future<void> _loadOrders() async {
    // Original order loading code...
  }

  // Tab content builders
  Widget _buildHomeTab() {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: ResellerComponent(violet: violet)),
              Expanded(child: DesignerComponent(violet: violet)),
              Expanded(child: TailorComponent(violet: violet)),
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
      return Card(
        margin: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(order['productImage'] ?? 'https://via.placeholder.com/100'),
            onBackgroundImageError: (_, __) => const Icon(Icons.error),
          ),
          title: Text(order['productName'] ?? 'Unknown Product'),
          subtitle: Text('${order['status'] ?? 'pending'} • \$${order['totalPrice']}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Show order details dialog
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(order['productName'] ?? 'Order Details'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${order['status']}'),
                    Text('Price: \$${order['totalPrice']}'),
                    Text('Seller: ${order['seller']}'),
                    Text('Date: ${order['orderedAt']}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
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
          
          // Sidebar overlay (moved to a separate component)
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
