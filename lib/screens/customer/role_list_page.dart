import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_detail_page.dart';

class RoleListPage extends StatefulWidget {
  final String roleType;

  const RoleListPage({
    Key? key,
    required this.roleType,
  }) : super(key: key);

  @override
  State<RoleListPage> createState() => _RoleListPageState();
}

class _RoleListPageState extends State<RoleListPage> {
  final Color violet = const Color(0xFFB878FF);
  final Color violetDark = const Color(0xFFB361F8);
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String? _errorMessage;
  
  final String apiBaseUrl = 'http://localhost:5000/api';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }

      print('Requesting users with role: ${widget.roleType.toLowerCase()}');
      
      final response = await http.get(
        Uri.parse('$apiBaseUrl/users?role=${widget.roleType.toLowerCase()}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        
        print('Found ${_users.length} users');
        _users.forEach((user) {
          print('User: id=${user['id']}, email=${user['email']}, role=${user['role']}');
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load ${widget.roleType}s: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roleType}s'),
        backgroundColor: violetDark,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
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
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(backgroundColor: violet),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No ${widget.roleType}s found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(backgroundColor: violet),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // List view of users with correct data display
    return ListView.builder(
      itemCount: _users.length,
      padding: const EdgeInsets.all(12.0),
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: violet,
              child: Icon(
                widget.roleType == 'Designer' 
                    ? Icons.design_services
                    : widget.roleType == 'Tailor'
                        ? Icons.cut
                        : Icons.store,
                color: Colors.white,
              ),
            ),
            title: Text(
              user['email'] ?? 'Unknown Email',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(height: 4),
    Text('Role: ${user['role'] ?? 'Unknown Role'}'),
    // Only show specialization if not null
    if (user['specialization'] != null) ...[
      const SizedBox(height: 4),
      Text('Specialization: ${user['specialization']}'),
    ],
  ],
),
            onTap: () {
              // Navigate to the detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoleDetailPage(
                    roleType: widget.roleType,
                    userId: user['id'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
