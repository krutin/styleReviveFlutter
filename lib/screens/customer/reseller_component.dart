import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'role_detail_page.dart';
import 'role_list_page.dart'; // New import for the list page

class ResellerComponent extends StatelessWidget {
  final Color violet;
  
  const ResellerComponent({
    Key? key,
    required this.violet,
  }) : super(key: key);

  void navigateToResellerPage(BuildContext context) {
    // Navigate to a list of resellers instead
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoleListPage(roleType: 'Reseller'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => navigateToResellerPage(context),
      child: Card(
        color: violet,
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Text('Reseller', style: const TextStyle(fontSize: 20, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
