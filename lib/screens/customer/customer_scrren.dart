import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CustomerScreen(),
  ));
}

class CustomerScreen extends StatefulWidget {
  final String? token;
  
  const CustomerScreen({super.key, this.token});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  bool _isSidebarOpen = false;
  int _selectedTab = 0;
  final List<String> tabs = ['Home', 'Orders', 'Profile'];
  final Color violet = const Color(0xFFB878FF);
  final Color violetDark = const Color(0xFFB361F8);
  
  // Orders data
  List<Map<String, dynamic>> _orders = [];
  bool _isOrdersLoading = false;

  @override
  void initState() {
    super.initState();
    _saveToken();
  }

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

  Future<void> _loadOrders() async {
    setState(() => _isOrdersLoading = true);
    
    try {
      final token = await _getToken();
      if (token == null) {
        // Handle not logged in
        return;
      }
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/customer/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data);
        });
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load orders')),
        );
      }
    } catch (e) {
      print("Error loading orders: $e");
      // Use mock data for testing
      setState(() {
        _orders = List.generate(3, (index) => {
          'id': 'order_$index',
          'productName': 'Product ${index + 1}',
          'productImage': 'https://via.placeholder.com/100',
          'seller': 'Reseller ${index + 1}',
          'totalPrice': (25.0 * (index + 1)),
          'status': ['pending', 'processing', 'delivered'][index % 3],
          'orderedAt': DateTime.now().subtract(Duration(days: index)).toString()
        });
      });
    } finally {
      setState(() => _isOrdersLoading = false);
    }
  }

  Widget _buildSidebarOverlay() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isSidebarOpen ? 200 : 0,
        color: violet,
        child: _isSidebarOpen
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() => _isSidebarOpen = false);
              },
            ),
            ...List.generate(
              tabs.length,
                  (index) => ListTile(
                title: Text(
                  tabs[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                    _isSidebarOpen = false;
                    
                    // Load orders when switching to Orders tab
                    if (index == 1) {
                      _loadOrders();
                    }
                  });
                },
              ),
            ),
            const Divider(color: Colors.white),
            ListTile(
              title:
              const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          // Clear token
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('auth_token');
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out')));
                          
                          // Navigate to login (if applicable)
                          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: violetDark),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        )
            : null,
      ),
    );
  }

  void _navigateToDetailPage(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleDetailPage(roleType: type),
      ),
    );
  }

  Widget _buildOptionCard(String title, IconData icon) {
    return GestureDetector(
      onTap: () => _navigateToDetailPage(title),
      child: Card(
        color: violet,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text(title, style: const TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildOptionCard('Reseller', Icons.store)),
              Expanded(child: _buildOptionCard('Designer', Icons.design_services)),
              Expanded(child: _buildOptionCard('Tailor', Icons.cut)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
<<<<<<< HEAD
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
=======
    final List<Map<String, String>> sampleOrders = [
      {'product': 'Product 1', 'seller': 'Reseller', 'status': 'Delivered'},
      {'product': 'Tailor Style 2', 'seller': 'Tailor', 'status': 'In Progress'},
      {'product': 'Designer Work 3', 'seller': 'Designer', 'status': 'Delivered'},
      {'product': 'Product 4', 'seller': 'Reseller', 'status': 'Pending'},
    ];

    return ListView.builder(
      itemCount: sampleOrders.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final order = sampleOrders[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(order['product']!),
            subtitle: Text('Seller: ${order['seller']}'),
            trailing: Text(
              order['status']!,
              style: TextStyle(
                color: order['status'] == 'Delivered'
                    ? Colors.green
                    : order['status'] == 'Pending'
                    ? Colors.orange
                    : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
>>>>>>> 55dcc169c3364eb9b7b2e4e8a6809c269460e71e
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
          Column(
            children: [
              Container(
                color: violetDark,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isSidebarOpen ? Icons.close : Icons.menu,
                        color: Colors.white,
                      ),
                      onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Customer Dashboard',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
              Expanded(child: _getSelectedTabContent()),
            ],
          ),
          _buildSidebarOverlay(),
        ],
      ),
    );
  }
}

class RoleDetailPage extends StatefulWidget {
  final String roleType;
  const RoleDetailPage({super.key, required this.roleType});

  @override
  State<RoleDetailPage> createState() => _RoleDetailPageState();
}

class _RoleDetailPageState extends State<RoleDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterItems);
    _loadData();
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }

      // Determine which API endpoint to call based on role type
      String endpoint;
      switch (widget.roleType) {
        case 'Reseller':
          endpoint = 'products';
          break;
        case 'Designer':
          endpoint = 'designer-works';
          break;
        case 'Tailor':
          endpoint = 'tailor-works';
          break;
        default:
          throw Exception('Invalid role type');
      }

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/customer/$endpoint'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _items = List<Map<String, dynamic>>.from(data);
          _filteredItems = _items;
        });
      } else {
        throw Exception('Failed to load items: ${response.statusCode}');
      }
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        _errorMessage = e.toString();
        
        // Use mock data for testing
        _items = generateMockData();
        _filteredItems = _items;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Function to generate mock data for each role (fallback)
  List<Map<String, dynamic>> generateMockData() {
    return List.generate(
      5,
          (index) {
        String title;
        String subtitle;
        List<String> images;

        switch (widget.roleType) {
          case 'Reseller':
            title = 'Product $index';
            subtitle = 'Price: \$${(10 + index) * 2}';
            images = [
              'https://via.placeholder.com/400x240?text=Reseller+${index + 1}',
              'https://via.placeholder.com/400x240?text=Reseller+${index + 1}+Alt'
            ];
            break;
          case 'Designer':
            title = 'Designer Work $index';
            subtitle = 'Traditional / Modern styles';
            images = [
              'https://via.placeholder.com/400x240?text=Designer+${index + 1}',
              'https://via.placeholder.com/400x240?text=Designer+${index + 1}+Alt'
            ];
            break;
          case 'Tailor':
            title = 'Tailor Style $index';
            subtitle = 'Custom measurements';
            images = [
              'https://via.placeholder.com/400x240?text=Tailor+${index + 1}',
              'https://via.placeholder.com/400x240?text=Tailor+${index + 1}+Alt'
            ];
            break;
          default:
            title = 'Item $index';
            subtitle = 'Details here';
            images = [
              'https://via.placeholder.com/400x240?text=Item+${index + 1}'
            ];
        }

        return {
          'id': 'mock_$index',
          'title': title,
          'subtitle': subtitle,
          'images': images,
        };
      },
    );
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _items;
      });
      return;
    }
    
    setState(() {
      _filteredItems = _items
          .where((item) =>
          item['title'].toString().toLowerCase().contains(query) ||
          item['subtitle'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onPlaceOrder(Map<String, dynamic> item) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }

      // Get shipping address from user
      final TextEditingController addressController = TextEditingController();
      final String? address = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Shipping Address'),
          content: TextField(
            controller: addressController,
            decoration: const InputDecoration(hintText: 'Enter your shipping address'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (addressController.text.trim().isNotEmpty) {
                  Navigator.pop(context, addressController.text.trim());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (address == null || address.isEmpty) {
        return; // User cancelled
      }

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/customer/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'productId': item['id'],
          'quantity': 1,
          'shippingAddress': address,
        }),
      );

      if (response.statusCode == 201) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order placed for "${item['title']}"')),
          );
        }
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      print("Error placing order: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed for "${item['title']}"')), // Mock success for demo
        );
      }
    }
  }

  void _onContact(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          itemTitle: item['title'],
          roleType: widget.roleType,
          receiverId: item[widget.roleType == 'Reseller' 
              ? 'sellerId' 
              : widget.roleType == 'Designer' 
                  ? 'designerId' 
                  : 'tailorId'] ?? 'unknown_id',
          itemId: item['id'],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(Map<String, dynamic> item) {
    List<String> images = List<String>.from(item['images'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image)),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              item['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              item['subtitle'] ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: ElevatedButton(
                onPressed: () {
                  if (widget.roleType == 'Reseller') {
                    _onPlaceOrder(item);
                  } else {
                    _onContact(item);
                  }
                },
                child: Text(widget.roleType == 'Reseller' ? 'Place Order' : 'Contact'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roleType} Products'),
        backgroundColor: const Color(0xFFB878FF),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty && _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredItems.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) =>
                                _buildVerticalCard(_filteredItems[index]),
                          ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String itemTitle;
  final String roleType;
  final String receiverId;
  final String? itemId;
  
  const ChatScreen({
    super.key, 
    required this.itemTitle, 
    required this.roleType,
    required this.receiverId,
    this.itemId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/customer/messages/${widget.receiverId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          for (var msg in data) {
            _messages.add({
              'text': msg['content'],
              'isFromMe': msg['senderId'] != widget.receiverId,
              'timestamp': msg['createdAt'],
            });
          }
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print("Error loading messages: $e");
      // Add mock messages for testing
      setState(() {
        _messages.addAll([
          {'text': 'Hello! I\'m interested in ${widget.itemTitle}', 'isFromMe': true, 'timestamp': DateTime.now().toString()},
          {'text': 'Hi there! How can I help you?', 'isFromMe': false, 'timestamp': DateTime.now().toString()},
        ]);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': text,
        'isFromMe': true,
        'timestamp': DateTime.now().toString(),
      });
      _controller.clear();
    });
    
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("Not authenticated");
      }
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/customer/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiverId': widget.receiverId,
          'content': text,
          'itemId': widget.itemId,
          'itemType': widget.roleType == 'Reseller' 
              ? 'product' 
              : widget.roleType == 'Designer'
                  ? 'designerWork'
                  : 'tailorWork',
        }),
      );
      
      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print("Error sending message: $e");
      // Message is already added to UI, so we don't need to show an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat about ${widget.itemTitle}'),
        backgroundColor: const Color(0xFFB878FF),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message['isFromMe'] 
                                ? Alignment.centerRight 
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10, 
                                horizontal: 16
                              ),
                              decoration: BoxDecoration(
                                color: message['isFromMe']
                                    ? Colors.purple.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(message['text']),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
