import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? selectedRole;

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
                  Text("Join Style Revive and start your fashion journey.",
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
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
                      onPressed: () {
                        // TODO: Implement signup logic
                        if (selectedRole == "reseller") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Reseller request submitted for admin approval.")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Signup functionality not implemented.")),
                          );
                        }
                      },
                      child: const Text("Sign Up"),
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