import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DesignerScreen(),
  ));
}

class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});

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
}

class DesignerOrder {
  final String client;
  final String address;
  final String event;
  final String status;

  DesignerOrder({
    required this.client,
    required this.address,
    required this.event,
    required this.status,
  });
}

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

class _DesignerScreenState extends State<DesignerScreen> {
  int _selectedTab = 0;
  String _specialization = 'Marriages';

  final List<DesignerWork> works = [
    DesignerWork(
      id: const Uuid().v4(),
      title: 'Wedding Couture',
      description: 'Elegant bridal designs with intricate embroidery.',
      imageUrls: ['https://via.placeholder.com/150', 'https://via.placeholder.com/140'],
    ),
    DesignerWork(
      id: const Uuid().v4(),
      title: 'Traditional Festival Wear',
      description: 'Bright ethnic outfits for cultural festivals.',
      imageUrls: ['https://via.placeholder.com/160'],
    ),
    DesignerWork(
      id: const Uuid().v4(),
      title: 'Modern Western Gowns',
      description: 'Sleek and stylish gowns for receptions.',
      imageUrls: ['https://via.placeholder.com/170'],
    ),
  ];

  final List<DesignerOrder> orders = [
    DesignerOrder(
      client: 'Rhea',
      address: '101 Park Lane, City',
      event: 'Marriage',
      status: 'In Progress',
    ),
    DesignerOrder(
      client: 'Aarav',
      address: '99 Residency Blvd, Town',
      event: 'Birthday',
      status: 'Completed',
    ),
  ];

  final Map<String, List<Message>> chatMap = {
    'Rhea': [
      Message(sender: 'Client', text: 'Can you design a bridal lehenga?'),
      Message(sender: 'Designer', text: 'Absolutely! Let’s discuss the style.'),
    ],
    'Aarav': [
      Message(sender: 'Client', text: 'I need a jacket for my birthday.'),
      Message(sender: 'Designer', text: 'Sure! Color preferences?'),
    ],
  };

  void _showAddWorkDialog({DesignerWork? workToEdit}) {
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
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newWork = DesignerWork(
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
                  Navigator.pop(context);
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
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => works.removeAt(index)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return ExpansionTile(
          title: Text('${order.client} - ${order.status}'),
          subtitle: Text('${order.event} • ${order.address}'),
        );
      },
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
                border: Border.all(color: Colors.black, width: 1), // black border
                borderRadius: BorderRadius.circular(4),
                color: Colors.white, // white background
              ),
              child: DropdownButton<String>(
                value: _specialization,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black), // black text style
                onChanged: (String? newValue) {
                  setState(() {
                    _specialization = newValue!;
                  });
                },
                items: ['Marriages', 'Birthdays', 'Traditional Wear', 'Western Wear']
                    .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.black)),
                ))
                    .toList(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Implement actual logout logic
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
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
        onTap: (index) => setState(() => _selectedTab = index),
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
    super.key,
    required this.customer,
    required this.messages,
    required this.onSend,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = Message(sender: 'Designer', text: text);
    widget.onSend(message);
    _controller.clear();
    setState(() {});
  }

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
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDesigner ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}