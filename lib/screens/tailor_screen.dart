import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TailorScreen(),
  ));
}

class TailorScreen extends StatefulWidget {
  const TailorScreen({super.key});

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
}

class TailorOrder {
  final String customer;
  final String address;
  final Map<String, String> measurements;
  final String status;

  TailorOrder({
    required this.customer,
    required this.address,
    required this.measurements,
    required this.status,
  });
}

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class _TailorScreenState extends State<TailorScreen> {
  int _selectedTab = 0;

  // --- Use previous working code for Works tab ---
  final List<TailorWork> works = [
    TailorWork(
      id: const Uuid().v4(),
      title: 'Custom Sherwani',
      description: 'A royal sherwani designed for weddings.',
      imageUrls: ['https://via.placeholder.com/150', 'https://via.placeholder.com/140'],
    ),
    TailorWork(
      id: const Uuid().v4(),
      title: 'Designer Kurta',
      description: 'Elegant kurta for festive occasions.',
      imageUrls: ['https://via.placeholder.com/130', 'https://via.placeholder.com/120'],
    ),
    TailorWork(
      id: const Uuid().v4(),
      title: 'Casual Shirt',
      description: 'Comfortable casual shirt for daily wear.',
      imageUrls: ['https://via.placeholder.com/110', 'https://via.placeholder.com/100'],
    ),
  ];

  // --- Orders sample data ---
  final List<TailorOrder> orders = [
    TailorOrder(
      customer: 'John',
      address: '123 Street, City',
      measurements: {'Chest': '38 in', 'Waist': '32 in', 'Length': '40 in'},
      status: 'In Progress',
    ),
    TailorOrder(
      customer: 'Ayesha',
      address: '456 Avenue, Town',
      measurements: {'Chest': '36 in', 'Waist': '30 in', 'Length': '42 in'},
      status: 'Completed',
    ),
  ];

  // --- Chat data ---
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

  // ---------------- Original Works Tab Code (with working add/edit/delete) ----------------
  void _showAddWorkDialog({TailorWork? workToEdit}) {
    final titleController = TextEditingController(text: workToEdit?.title ?? '');
    final descriptionController = TextEditingController(text: workToEdit?.description ?? '');
    final imageUrls = List<TextEditingController>.from(
      (workToEdit?.imageUrls ?? ['']).map((url) => TextEditingController(text: url)),
    );

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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title and Description cannot be empty')),
                    );
                    return;
                  }
                  final newWork = TailorWork(
                    id: workToEdit?.id ?? const Uuid().v4(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    imageUrls: imageUrls.map((c) => c.text.trim()).where((url) => url.isNotEmpty).toList(),
                  );

                  setState(() {
                    if (workToEdit == null) {
                      works.add(newWork);
                    } else {
                      final idx = works.indexWhere((w) => w.id == workToEdit.id);
                      if (idx != -1) works[idx] = newWork;
                    }
                  });

                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              )
            ],
          );
        });
      },
    );
  }

  Widget _buildWorksTab() {
    return ListView.builder(
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
                      onPressed: () {
                        _showAddWorkDialog(workToEdit: work);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          works.removeAt(index);
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- Orders Tab ---------------------
  Widget _buildOrdersTab() {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ExpansionTile(
          title: Text('${order.customer} - ${order.status}'),
          subtitle: Text(order.address),
          children: order.measurements.entries
              .map((e) => ListTile(title: Text('${e.key}: ${e.value}')))
              .toList(),
        );
      },
    );
  }

  // ---------------- Chat List Tab ---------------------
  Widget _buildChatListTab() {
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

  // ---------------- Scaffold ---------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
                        // TODO: Add actual logout logic here if needed.
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: [
        _buildWorksTab(),
        _buildOrdersTab(),
        _buildChatListTab(),
      ][_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.design_services), label: 'Works'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
        onPressed: () {
          _showAddWorkDialog();
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

// ---------------- Chat Page ---------------------
class ChatPage extends StatefulWidget {
  final String customer;
  final List<Message> messages;
  final void Function(Message) onSend;

  const ChatPage({
    super.key,
    required this.customer,
    required this.messages,
    required this.onSend,
  });

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
}