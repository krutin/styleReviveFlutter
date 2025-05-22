import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Debugging: Print input values
    print("Email: $email");
    print("Password: $password");

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // Debugging: Print request body before sending
      final requestBody = jsonEncode({
        'email': email,
        'password': password,
      });
      print("Request Body: $requestBody");

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'), // TODO: replace with your IP
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Debugging: Print response status and body
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _showMessage(result['message']);
        // TODO: Handle successful login (e.g., save token, navigate to home screen)
      } else {
        _showMessage(result['message'] ?? 'Login failed.');
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
                  Icon(Icons.lock_outline, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text("Welcome Back!", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Enter your email and password to access your account.",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                      textAlign: TextAlign.center),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: isLoading
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Log In"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text("Don’t have an account? Sign Up"),
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
