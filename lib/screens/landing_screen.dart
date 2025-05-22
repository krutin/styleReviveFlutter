import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const LandingScreen({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary, // Ensure good contrast
        title: Text(
          'StyleRevive',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
            child: Text(
              'Login',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SignupScreen()),
              );
            },
            child: Text(
              'Sign Up',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: colorScheme.onPrimary,
            ),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // Welcome section
            Column(
              children: [
                Icon(Icons.auto_awesome,
                    size: 64, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Style Revive',
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover unique fashion pieces, talented designers, and skilled tailors. Give your wardrobe a new life.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignupScreen()),
                    );
                  },
                  child: const Text('Join as a Seller'),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // What We Offer
            Text(
              'What We Offer',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.9,
                children: [
                  _FeatureCard(
                    icon: FontAwesomeIcons.shoppingBag,
                    title: 'Unique Resellers',
                    description:
                    'Find curated collections from passionate resellers. Vintage, pre-loved, and unique finds await.',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  _FeatureCard(
                    icon: FontAwesomeIcons.palette,
                    title: 'Talented Designers',
                    description:
                    'Connect with innovative fashion designers for custom creations or to shop their latest designs.',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  _FeatureCard(
                    icon: FontAwesomeIcons.scissors,
                    title: 'Skilled Tailors',
                    description:
                    'Need alterations or custom-fitted garments? Find expert tailors to perfect your look.',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              );
            }),

            const SizedBox(height: 48),

            // Call to Action
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to Revive Your Style?',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join our community today and start exploring a world of fashion possibilities.',
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SignupScreen()),
                      );
                    },
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}