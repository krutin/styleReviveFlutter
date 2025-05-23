import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CustomerScreen(),
  ));
}

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  bool _isSidebarOpen = false;
  int _selectedTab = 0;
  final List<String> tabs = ['Home', 'Orders', 'Profile'];
  final Color violet = const Color(0xFFB878FF);
  final Color violetDark = const Color(0xFFB361F8);

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
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out')));
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
    return const Center(child: Text('Your past and current orders will appear here.'));
  }

  Widget _buildProfileTab() {
    return const Center(child: Text('User profile settings and information.'));
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

  // Function to generate mock data for each role
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
          'title': title,
          'subtitle': subtitle,
          'images': images,
        };
      },
    );
  }

  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _filteredData = generateMockData();
    _searchController.addListener(_filterData);
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = generateMockData()
          .where((item) =>
      item['title'].toLowerCase().contains(query) ||
          item['subtitle'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onPlaceOrder(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed for "$productName"')),
    );
  }

  void _onContact(String itemTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(itemTitle: itemTitle, roleType: widget.roleType),
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
                    _onPlaceOrder(item['title']);
                  } else {
                    _onContact(item['title']);
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
            child: _filteredData.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.builder(
              itemCount: _filteredData.length,
              itemBuilder: (context, index) =>
                  _buildVerticalCard(_filteredData[index]),
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
  const ChatScreen({super.key, required this.itemTitle, required this.roleType});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> _messages = [];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(text);
      _controller.clear();
    });
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
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    const InputDecoration(hintText: 'Type a message'),
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
}