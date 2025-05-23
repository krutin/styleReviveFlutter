import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_screen.dart';
import 'reseller_screen.dart'; // Import reseller dashboard
import 'tailor_screen.dart'; // Import tailor dashboard
// import 'designer_dashboard.dart'; // Import designer dashboard
// import 'customer_dashboard.dart'; // Import customer dashboard

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

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'), // Replace with your backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _showMessage(result['message']);

        // Redirect based on role
        final role = result['user']['role']; // Assuming the backend returns the user's role
        if (role == 'reseller') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ResellerDashboard(token : result['token'])), // Pass the token to the dashboard
          );
        } else if (role == 'tailor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TailorScreen(token : result['token'])), // Pass the token to the dashboard
          );
        } else if (role == 'customer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ResellerDashboard(token : result['token'])), //temp
          );
        } else {
          _showMessage("Unknown role. Please contact support.");
        }
      } else {
        _showMessage(result['message'] ?? 'Login failed.');
      }
    } catch (e) {
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
