import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_list_page.dart'; // Updated import

class TailorComponent extends StatelessWidget {
  final Color violet;
  
  const TailorComponent({
    Key? key,
    required this.violet,
  }) : super(key: key);

  void navigateToTailorPage(BuildContext context) {
    // Navigate to list of tailors first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleListPage(roleType: 'Tailor'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToTailorPage(context),
      child: Card(
        color: violet,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cut, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text('Tailor', style: const TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
