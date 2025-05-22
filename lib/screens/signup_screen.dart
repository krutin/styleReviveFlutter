import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? selectedRole;
  bool isLoading = false;

  Future<void> _signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || selectedRole == null) {
      _showMessage("Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Debugging: Print request body before sending
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
        'role': selectedRole,
      });
      print("Request Body: $requestBody");

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/signup'), // TODO: replace with your IP
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Debugging: Print response status and body
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showMessage(result['message']);
        if (selectedRole != "reseller") {
          // Navigate to login screen after signup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        _showMessage(result['message'] ?? 'Signup failed.');
      }
    } catch (e) {
      // Debugging: Print error
      print("Error: $e");
      _showMessage("Error connecting to server.");
    }

    setState(() => isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text("Create an Account", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    "Join Style Revive and start your fashion journey.",
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "I am a..."),
                    value: selectedRole,
                    items: const [
                      DropdownMenuItem(value: "reseller", child: Text("Reseller")),
                      DropdownMenuItem(value: "designer", child: Text("Designer")),
                      DropdownMenuItem(value: "tailor", child: Text("Tailor")),
                      DropdownMenuItem(value: "customer", child: Text("Customer")),
                    ],
                    onChanged: (value) => setState(() => selectedRole = value),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _signup,
                      child: isLoading
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Sign Up"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Already have an account? Log In"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
