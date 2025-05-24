import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_list_page.dart'; // Updated import

class DesignerComponent extends StatelessWidget {
  final Color violet;
  
  const DesignerComponent({
    Key? key,
    required this.violet,
  }) : super(key: key);

  void navigateToDesignerPage(BuildContext context) {
    // Navigate to list of designers first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleListPage(roleType: 'Designer'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToDesignerPage(context),
      child: Card(
        color: violet,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.design_services, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text('Designer', style: const TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
