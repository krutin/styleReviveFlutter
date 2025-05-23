import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DesignerScreen extends StatefulWidget {
  final String token;
  
  const DesignerScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}

class DesignerWork {
  final String id;
  String title;
  String description;
  List<String> imageUrls;

  DesignerWork({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrls,
  });
  
  factory DesignerWork.fromJson(Map<String, dynamic> json) {
    return DesignerWork(
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

class DesignerOrder {
  final String id;
  final String client;
  final String address;
  final String event;
  String status;
  final Map<String, String> measurements;

  DesignerOrder({
    required this.id,
    required this.client,
    required this.address,
    required this.event,
    required this.status,
    required this.measurements,
  });
  
  factory DesignerOrder.fromJson(Map<String, dynamic> json) {
    Map<String, String> measurementsMap = {};
    if (json['measurements'] is Map) {
      json['measurements'].forEach((key, value) {
        measurementsMap[key] = value.toString();
      });
    }
    
    return DesignerOrder(
      id: json['_id'] ?? '',
      client: json['client'] ?? '',
      address: json['address'] ?? '',
      event: json['event'] ?? '',
      status: json['status'] ?? 'In Progress',
      measurements: measurementsMap,
    );
  }
}

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class _DesignerScreenState extends State<DesignerScreen> {
  int _selectedTab = 0;
  String _specialization = 'Marriages';
  bool _isLoading = false;
  String _errorMessage = '';
  
  // API base URL
  final String baseUrl = 'http://localhost:5000/api';
  
  // Data
  List<DesignerWork> works = [];
  List<DesignerOrder> orders = [];
  
  // Chat data (still using mock data as API not implemented)
  final Map<String, List<Message>> chatMap = {
    'Rhea': [
      Message(sender: 'Client', text: 'Can you design a bridal lehenga?'),
      Message(sender: 'Designer', text: 'Absolutely! Let\'s discuss the style.'),
    ],
    'Aarav': [
      Message(sender: 'Client', text: 'I need a jacket for my birthday.'),
      Message(sender: 'Designer', text: 'Sure! Color preferences?'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _saveToken();
    _loadDesignerProfile();
    _loadData();
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', widget.token);
  }
  
  Future<void> _loadDesignerProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/designer/profile'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _specialization = data['specialization'] ?? 'Marriages';
        });
      }
    } catch (e) {
      print("Failed to load designer profile: $e");
    }
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
      print("Error loading data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // API Methods
  Future<void> _fetchWorks() async {
    try {
      print("Fetching designer works...");
      final response = await http.get(
        Uri.parse('$baseUrl/designerworks'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          works = data.map((json) => DesignerWork.fromJson(json)).toList();
        });
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, use mock data
        print("WARNING: Endpoint not found. Using mock data for development.");
        setState(() {
          works = [
            DesignerWork(
              id: '1',
              title: 'Wedding Couture',
              description: 'Elegant bridal designs with intricate embroidery.',
              imageUrls: ['https://via.placeholder.com/150', 'https://via.placeholder.com/140'],
            ),
            DesignerWork(
              id: '2',
              title: 'Traditional Festival Wear',
              description: 'Bright ethnic outfits for cultural festivals.',
              imageUrls: ['https://via.placeholder.com/160'],
            ),
          ];
        });
      } else {
        throw Exception('Failed to load works: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _fetchWorks: $e");
      throw e;
    }
  }
  
  Future<void> _fetchOrders() async {
    try {
      print("Fetching designer orders...");
      final response = await http.get(
        Uri.parse('$baseUrl/designerorders'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          orders = data.map((json) => DesignerOrder.fromJson(json)).toList();
        });
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, use mock data
        print("WARNING: Endpoint not found. Using mock data for development.");
        setState(() {
          orders = [
            DesignerOrder(
              id: '1',
              client: 'Rhea',
              address: '101 Park Lane, City',
              event: 'Marriage',
              status: 'In Progress',
              measurements: {
                'Bust': '34 in',
                'Waist': '28 in',
                'Hips': '36 in',
                'Height': '5\'6"',
              },
            ),
            DesignerOrder(
              id: '2',
              client: 'Aarav',
              address: '99 Residency Blvd, Town',
              event: 'Birthday',
              status: 'Completed',
              measurements: {
                'Chest': '38 in',
                'Waist': '32 in',
                'Sleeve Length': '24 in',
                'Height': '5\'10"',
              },
            ),
          ];
        });
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _fetchOrders: $e");
      throw e;
    }
  }
  
  Future<void> _createWork(DesignerWork work) async {
    try {
      print("Creating designer work...");
      final response = await http.post(
        Uri.parse('$baseUrl/designerworks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(work.toJson()),
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 201) {
        // Work created successfully
        await _fetchWorks(); // Refresh the works list
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, use mock data
        print("WARNING: Endpoint not found. Simulating success for development.");
        setState(() {
          final newWork = DesignerWork(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: work.title,
            description: work.description,
            imageUrls: work.imageUrls,
          );
          works.add(newWork);
        });
      } else {
        throw Exception('Failed to create work: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _createWork: $e");
      throw e;
    }
  }
  
  Future<void> _updateWork(String id, DesignerWork work) async {
    try {
      print("Updating designer work...");
      final response = await http.put(
        Uri.parse('$baseUrl/designerworks/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(work.toJson()),
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        // Work updated successfully
        await _fetchWorks(); // Refresh the works list
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, use mock data
        print("WARNING: Endpoint not found. Simulating success for development.");
        setState(() {
          final index = works.indexWhere((w) => w.id == id);
          if (index != -1) {
            works[index] = work;
          }
        });
      } else {
        throw Exception('Failed to update work: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _updateWork: $e");
      throw e;
    }
  }
  
  Future<void> _deleteWork(String id) async {
    try {
      print("Deleting designer work...");
      final response = await http.delete(
        Uri.parse('$baseUrl/designerworks/$id'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        // Work deleted successfully
        await _fetchWorks(); // Refresh the works list
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, use mock data
        print("WARNING: Endpoint not found. Simulating success for development.");
        setState(() {
          works.removeWhere((w) => w.id == id);
        });
      } else {
        throw Exception('Failed to delete work: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _deleteWork: $e");
      throw e;
    }
  }
  
  Future<void> _updateSpecialization(String specialization) async {
    try {
      print("Updating specialization...");
      final response = await http.put(
        Uri.parse('$baseUrl/designer/specialization'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'specialization': specialization}),
      );
      
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        // Specialization updated successfully
        setState(() {
          _specialization = specialization;
        });
      } else if (response.statusCode == 404) {
        // If endpoint doesn't exist yet, just update local state
        print("WARNING: Endpoint not found. Updating local state only.");
        setState(() {
          _specialization = specialization;
        });
      } else {
        throw Exception('Failed to update specialization: ${response.statusCode}');
      }
    } catch (e) {
      print("Exception in _updateSpecialization: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update specialization: $e')),
      );
    }
  }

  void _showAddWorkDialog({DesignerWork? workToEdit}) {
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
                    const Text('Image URLs', style: TextStyle(fontWeight: FontWeight.bold)),
                    Column(
                      children: imageUrls
                          .asMap()
                          .entries
                          .map((entry) => Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(labelText: 'Image URL ${entry.key + 1}'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setStateDialog(() => imageUrls.removeAt(entry.key));
                            },
                          ),
                        ],
                      ))
                          .toList(),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Image URL'),
                      onPressed: () => setStateDialog(() => imageUrls.add(TextEditingController())),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (titleController.text.trim().isEmpty ||
                            descriptionController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Title and Description cannot be empty')),
                          );
                          return;
                        }
                        
                        setStateDialog(() {
                          isSaving = true;
                        });
                        
                        try {
                          final newWork = DesignerWork(
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
                            Navigator.pop(context);
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              )
            ],
          );
        });
      },
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
          return ExpansionTile(
            title: Text('${order.client} - ${order.status}'),
            subtitle: Text('${order.event} • ${order.address}'),
            children: [
              ...order.measurements.entries.map((entry) {
                return ListTile(
                  title: Text('${entry.key}: ${entry.value}'),
                  dense: true,
                );
              }).toList(),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: order.status == "Completed" ? null : () async {
                      try {
                        final response = await http.patch(
                          Uri.parse('$baseUrl/designerorders/${order.id}/status'),
                          headers: {
                            'Content-Type': 'application/json',
                            'Authorization': 'Bearer ${widget.token}',
                          },
                          body: jsonEncode({'status': 'Completed'}),
                        );
                        
                        if (response.statusCode == 200) {
                          setState(() {
                            order.status = "Completed";
                          });
                        } else if (response.statusCode == 404) {
                          // If endpoint doesn't exist, simulate success
                          setState(() {
                            order.status = "Completed";
                          });
                        } else {
                          throw Exception('Failed to update status');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text('Mark as Completed'),
                  )
                ],
              )
            ],
          );
        },
      ),
    );
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
                  Text(work.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(work.description),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 140,
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
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 140),
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
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: Text('Are you sure you want to delete "${work.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            try {
                              await _deleteWork(work.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error deleting work: $e')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTab() {
    return ListView(
      children: chatMap.keys.map((client) {
        return ListTile(
          title: Text(client),
          trailing: const Icon(Icons.chat),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) {
              return ChatPage(
                customer: client,
                messages: chatMap[client]!,
                onSend: (msg) {
                  setState(() {
                    chatMap[client]!.add(msg);
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
        title: const Text('Designer Dashboard'),
        actions: [
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _specialization,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateSpecialization(newValue);
                  }
                },
                items: ['Marriages', 'Birthdays', 'Traditional Wear', 'Western Wear']
                    .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.black)),
                )).toList(),
              ),
            ),
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
                      child: const Text('Cancel')
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                // Clear auth token
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                
                // Navigate back to login screen
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildWorksTab(),
          _buildOrdersTab(),
          _buildChatTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() => _selectedTab = index);
          _loadData();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Works'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
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
                final isDesigner = msg.sender == 'Designer';

                return Align(
                  alignment: isDesigner ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDesigner ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: isDesigner ? Colors.white : Colors.black),
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
                      final message = Message(sender: 'Designer', text: controller.text.trim());
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
