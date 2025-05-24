import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RoleDetailPage extends StatefulWidget {
  final String roleType;
  final String userId;

  const RoleDetailPage({
    Key? key, 
    required this.roleType,
    required this.userId,
  }) : super(key: key);

  @override
  State<RoleDetailPage> createState() => _RoleDetailPageState();
}

class _RoleDetailPageState extends State<RoleDetailPage> {
  final Color violet = const Color(0xFFB878FF);
  final Color violetDark = const Color(0xFFB361F8);
  
  bool _isUserLoading = true;
  bool _isPostsLoading = true;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _userPosts = [];
  String? _errorMessage;
  
  final String apiBaseUrl = 'http://localhost:5000/api';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Helper function for safe string conversion
  String safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isUserLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isUserLoading = false;
        });
        return;
      }

      // Debug log for API request
      print('Requesting user data: $apiBaseUrl/users/${widget.userId}');
      
      // Fetch specific user data by ID
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('User data response status: ${response.statusCode}');
      print('User data response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userData = data;
          _isUserLoading = false;
        });
        
        // After user data loads successfully, load their posts
        _loadUserPosts();
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'User not found. The requested profile may have been removed.';
          _isUserLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user data: ${response.statusCode}';
          _isUserLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isUserLoading = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isPostsLoading = true);

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() => _isPostsLoading = false);
        return;
      }

      // Debug log for API request
      print('Requesting posts: $apiBaseUrl/posts/user/${widget.userId}');

      // Fetch posts by user ID
      final response = await http.get(
        Uri.parse('$apiBaseUrl/posts/user/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Posts response status: ${response.statusCode}');
      print('Posts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userPosts = List<Map<String, dynamic>>.from(data);
          _isPostsLoading = false;
        });
      } else {
        print('Failed to load posts: ${response.statusCode}');
        setState(() {
          _userPosts = [];
          _isPostsLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        _userPosts = [];
        _isPostsLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _navigateToChat() {
    if (_userData == null) return;
    
    // Get values with safe null handling
    final String userId = safeString(_userData?['id']);
    final String userName = safeString(_userData?['email'], defaultValue: 'Unknown');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientId: userId,
          recipientName: userName,
          recipientRole: widget.roleType,
          apiBaseUrl: apiBaseUrl,
        ),
      ),
    );
  }

  Future<void> _placeOrder(Map<String, dynamic> post, int quantity, String notes) async {
    Navigator.pop(context); // Close the dialog
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await _getToken();
      if (token == null) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication required')),
          );
        }
        return;
      }

      // Safely extract values with proper null handling
      final String productId = safeString(post['id']);
      final String title = safeString(post['title'], defaultValue: 'No title');
      final String? image = post['image']?.toString();
      final String priceStr = safeString(post['price'], defaultValue: '0');
      final double price = double.tryParse(priceStr) ?? 0;
      final double totalPrice = price * quantity;

      final orderData = {
        'sellerId': widget.userId,
        'productId': productId,
        'productName': title,
        'productImage': image,
        'totalPrice': totalPrice.toString(),
        'quantity': quantity,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$apiBaseUrl/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(orderData),
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to place order: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.toString()}')),
        );
      }
    }
  }

  void _showOrderDialog(Map<String, dynamic> post) {
    // Handle potential null values in the post map
    final String title = safeString(post['title'], defaultValue: 'No title');
    final String description = safeString(post['description'], defaultValue: 'No description');
    final String price = safeString(post['price'], defaultValue: '0');
    final String? image = post['image']?.toString();
    
    final TextEditingController quantityController = TextEditingController(text: '1');
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order: $title'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle image display based on type (base64 or URL)
              if (image != null && image.isNotEmpty)
                _buildProductImage(image),
              const SizedBox(height: 12),
              Text('Price: \$$price', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _placeOrder(
              post,
              int.tryParse(quantityController.text) ?? 1,
              notesController.text,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: violetDark),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  // Helper method to build product image based on type
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userData != null ? safeString(_userData!['email'], defaultValue: 'User') : '${widget.roleType} Details'),
        backgroundColor: violetDark,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isUserLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(backgroundColor: violet),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No ${widget.roleType} data found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(backgroundColor: violet),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserProfileHeader(),
          const Divider(height: 1),
          _buildUserInfoSection(),
          const Divider(height: 1),
          _buildPostsSection(),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: violetDark,
                child: Icon(
                  widget.roleType == 'Designer' 
                      ? Icons.design_services
                      : widget.roleType == 'Tailor'
                          ? Icons.cut
                          : Icons.store,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeString(_userData!['email'], defaultValue: 'Unknown Email'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${safeString(_userData!['role'], defaultValue: widget.roleType)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    // Only show specialization if not null
                    if (_userData!['specialization'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Specialization: ${safeString(_userData!['specialization'])}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text('Contact'),
                          onPressed: _navigateToChat,
                          style: ElevatedButton.styleFrom(backgroundColor: violetDark),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.email),
                          label: const Text('Email'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Send email to: ${safeString(_userData!['email'], defaultValue: "User")}')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.email, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                safeString(_userData!['email'], defaultValue: 'Email not available'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _userData!['specialization'] != null 
              ? Text(
                  'Specializes in ${safeString(_userData!['specialization'])}',
                  style: const TextStyle(fontSize: 16),
                )
              : const Text(
                  'No specialization information available',
                  style: TextStyle(fontSize: 16),
                ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    // Section title based on role type
    String sectionTitle;
    if (widget.roleType == 'Designer') {
      sectionTitle = 'Designs';
    } else if (widget.roleType == 'Tailor') {
      sectionTitle = 'Services';
    } else {
      sectionTitle = 'Products';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            sectionTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _isPostsLoading
            ? const Center(child: CircularProgressIndicator())
            : _userPosts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          'No ${sectionTitle.toLowerCase()} available',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadUserPosts,
                          style: ElevatedButton.styleFrom(backgroundColor: violet),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _userPosts.length,
                    itemBuilder: (context, index) {
                      final post = _userPosts[index];
                      
                      // Safely extract values with proper null handling
                      final String title = safeString(post['title'], defaultValue: 'No title');
                      final String description = safeString(post['description'], defaultValue: 'No description');
                      final String price = safeString(post['price'], defaultValue: '0');
                      final String? image = post['image']?.toString();
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (image != null && image.isNotEmpty)
                              _buildProductImage(image),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(description),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '\$$price',
                                        style: const TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showOrderDialog(post),
                                        style: ElevatedButton.styleFrom(backgroundColor: violetDark),
                                        child: const Text('Order Now'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ],
    );
  }
}

// ChatScreen class with basic implementation
class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientRole;
  final String apiBaseUrl;

  const ChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientRole,
    required this.apiBaseUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final Color violetDark = const Color(0xFFB361F8);
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await _getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Fetch messages
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/messages/${widget.recipientId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.clear();
          if (data is List) {
            _messages.addAll(List<Map<String, dynamic>>.from(data));
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _messages.clear();
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'me',
      'receiverId': widget.recipientId,
      'content': message,
      'createdAt': DateTime.now().toIso8601String(),
      'read': false,
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    
    // Simple implementation - replace with your actual API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName),
            Text(
              widget.recipientRole,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: violetDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('No messages yet'),
                            const SizedBox(height: 8),
                            Text('Start a conversation with ${widget.recipientName}',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final message = _messages[_messages.length - 1 - index];
                          final isMe = message['senderId'] == 'me';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? violetDark : Colors.grey[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                message['content']?.toString() ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attachment feature coming soon')),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: violetDark),
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
