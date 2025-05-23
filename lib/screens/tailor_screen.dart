import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TailorScreen extends StatefulWidget {
  final String token;

  const TailorScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TailorScreen> createState() => _TailorScreenState();
}

class TailorWork {
  final String id;
  String title;
  String description;
  List<String> imageUrls;

  TailorWork({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
  });

  factory TailorWork.fromJson(Map<String, dynamic> json) {
    return TailorWork(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
    };
  }
}

class TailorOrder {
  final String id;
  final String customer;
  final String address;
  final Map<String, String> measurements;
  final String status;

  TailorOrder({
    required this.id,
    required this.customer,
    required this.address,
    required this.measurements,
    required this.status,
  });

  factory TailorOrder.fromJson(Map<String, dynamic> json) {
    Map<String, String> measurementsMap = {};
    if (json['measurements'] is Map) {
      json['measurements'].forEach((key, value) {
        measurementsMap[key] = value.toString();
      });
    }

    return TailorOrder(
      id: json['_id'] ?? '',
      customer: json['customer'] ?? '',
      address: json['address'] ?? '',
      measurements: measurementsMap,
      status: json['status'] ?? 'In Progress',
    );
  }
}

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class _TailorScreenState extends State<TailorScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Data
  List<TailorWork> works = [];
  List<TailorOrder> orders = [];
  
  // For chat (mock data since not implemented in backend)
  final Map<String, List<Message>> chatMap = {
    'John': [
      Message(sender: 'Customer', text: 'Hello, I need a custom kurta.'),
      Message(sender: 'Tailor', text: 'Sure, please provide your measurements.'),
    ],
    'Ayesha': [
      Message(sender: 'Customer', text: 'Can you make a designer lehenga?'),
      Message(sender: 'Tailor', text: 'Yes, please share your preferences.'),
    ],
  };

  @override
  void initState() {
    super.initState();
    // Save token to shared preferences for later use
    _saveToken();
    _loadData();
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', widget.token);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_selectedTab == 0) {
        await _fetchWorks();
      } else if (_selectedTab == 1) {
        await _fetchOrders();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API Methods
  Future<void> _fetchWorks() async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/api/works'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        works = data.map((json) => TailorWork.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load works: ${response.statusCode}');
    }
  }

  Future<void> _fetchOrders() async {
    final response = await http.get(
      Uri.parse('http://localhost:5000/api/Orders'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        orders = data.map((json) => TailorOrder.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }

  Future<void> _createWork(TailorWork work) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/works'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(work.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create work: ${response.statusCode}');
    }
  }

  Future<void> _updateWork(String id, TailorWork work) async {
    final response = await http.put(
      Uri.parse('http://localhost:5000/api/works/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode(work.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update work: ${response.statusCode}');
    }
  }

  Future<void> _deleteWork(String id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/works/$id'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete work: ${response.statusCode}');
    }
  }

  void _showAddWorkDialog({TailorWork? workToEdit}) {
    final titleController = TextEditingController(text: workToEdit?.title ?? '');
    final descriptionController = TextEditingController(text: workToEdit?.description ?? '');
    final imageUrls = List<TextEditingController>.from(
      (workToEdit?.imageUrls ?? [''])
          .map((url) => TextEditingController(text: url)),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(workToEdit == null ? 'Add Work' : 'Edit Work'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Image URLs:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Column(
                      children: imageUrls
                          .asMap()
                          .entries
                          .map((entry) => Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: entry.value,
                                      decoration: InputDecoration(
                                        labelText: 'Image URL ${entry.key + 1}',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () {
                                      setStateDialog(() {
                                        imageUrls.removeAt(entry.key);
                                      });
                                    },
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Image URL'),
                      onPressed: () {
                        setStateDialog(() {
                          imageUrls.add(TextEditingController());
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Title and Description cannot be empty')),
                          );
                          return;
                        }

                        setStateDialog(() {
                          isSaving = true;
                        });
                        
                        try {
                          final newWork = TailorWork(
                            id: workToEdit?.id ?? '',
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            imageUrls: imageUrls
                                .map((c) => c.text.trim())
                                .where((url) => url.isNotEmpty)
                                .toList(),
                          );

                          if (workToEdit == null) {
                            await _createWork(newWork);
                          } else {
                            await _updateWork(workToEdit.id, newWork);
                          }
                          
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            _loadData(); // Refresh data after saving
                          }
                        } catch (e) {
                          setStateDialog(() {
                            isSaving = false;
                          });
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              )
            ],
          );
        });
      },
    );
  }

  Future<void> _confirmDelete(TailorWork work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${work.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _deleteWork(work.id);
        _loadData(); // Refresh after deletion
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildWorksTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (works.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No works found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddWorkDialog(),
              child: const Text('Add Work'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: works.length,
        itemBuilder: (context, index) {
          final work = works[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(work.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(work.description),
                  const SizedBox(height: 10),
                  if (work.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: work.imageUrls.map((url) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ButtonBar(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddWorkDialog(workToEdit: work),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(work),
                        tooltip: 'Delete',
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              title: Text('${order.customer} - ${order.status}'),
              subtitle: Text(order.address),
              children: order.measurements.entries
                  .map((e) => ListTile(title: Text('${e.key}: ${e.value}')))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatListTab() {
    // Chat tab still uses mock data as it's not implemented in backend
    return ListView(
      children: chatMap.keys.map((customer) {
        return ListTile(
          title: Text(customer),
          trailing: const Icon(Icons.chat),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) {
              return ChatPage(
                customer: customer,
                messages: chatMap[customer]!,
                onSend: (msg) {
                  setState(() {
                    chatMap[customer]!.add(msg);
                  });
                },
              );
            }));
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                
                Navigator.of(context).pop(); // Return to login screen
              }
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildWorksTab(),
          _buildOrdersTab(),
          _buildChatListTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) {
          setState(() => _selectedTab = i);
          _loadData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.design_services), label: 'Works'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => _showAddWorkDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ChatPage extends StatefulWidget {
  final String customer;
  final List<Message> messages;
  final void Function(Message) onSend;

  const ChatPage({
    Key? key,
    required this.customer,
    required this.messages,
    required this.onSend,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.customer}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final msg = widget.messages[index];
                final isTailor = msg.sender == 'Tailor';

                return Align(
                  alignment: isTailor ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isTailor ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: isTailor ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter message',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      final message = Message(sender: 'Tailor', text: controller.text.trim());
                      widget.onSend(message);
                      setState(() {
                        controller.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
