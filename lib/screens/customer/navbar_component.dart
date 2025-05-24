import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavbarComponent extends StatelessWidget {
  final bool isSidebarOpen;
  final Function(bool) onSidebarToggle;
  final int selectedTab;
  final Function(int) onTabSelect;
  final List<String> tabs;
  final Color violetDark;
  
  const NavbarComponent({
    Key? key,
    required this.isSidebarOpen,
    required this.onSidebarToggle,
    required this.selectedTab,
    required this.onTabSelect,
    required this.tabs,
    required this.violetDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context),
      ],
    );
  }
  
  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: violetDark,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isSidebarOpen ? Icons.close : Icons.menu,
                color: Colors.white,
              ),
              onPressed: () => onSidebarToggle(!isSidebarOpen),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Customer Dashboard',
                style: TextStyle(color: Colors.white, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Tab navigation in top bar
            ...tabs.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onTabSelect(entry.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedTab == entry.key 
                          ? Colors.white.withOpacity(0.2) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarOverlay extends StatelessWidget {
  final bool isOpen;
  final Function(bool) onToggle;
  final Color violet;
  final Color violetDark;

  const SidebarOverlay({
    Key? key,
    required this.isOpen,
    required this.onToggle,
    required this.violet,
    required this.violetDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Using positioned fill for better overlay behavior
    return Positioned.fill(
      child: Stack(
        children: [
          // Semi-transparent background when sidebar is open
          if (isOpen)
            GestureDetector(
              onTap: () => onToggle(false),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
          
          // The actual sidebar
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: isOpen ? 250 : 0,
              decoration: BoxDecoration(
                color: violet,
                boxShadow: isOpen
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: isOpen
                  ? SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Menu',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => onToggle(false),
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white54, height: 1),
                          // User profile section
                          _buildUserProfileSection(),
                          const Divider(color: Colors.white54, height: 1),
                          // Sidebar options (different from tabs)
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                _buildSidebarOption(
                                  icon: Icons.settings,
                                  title: 'Settings',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Settings coming soon'))
                                    );
                                    onToggle(false);
                                  },
                                ),
                                _buildSidebarOption(
                                  icon: Icons.help_outline,
                                  title: 'Help & Support',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Help coming soon'))
                                    );
                                    onToggle(false);
                                  },
                                ),
                                _buildSidebarOption(
                                  icon: Icons.info_outline,
                                  title: 'About Us',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('About Us coming soon'))
                                    );
                                    onToggle(false);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white54, height: 1),
                          // Logout option
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.white),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => _showLogoutDialog(context),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Customer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarOption({
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('auth_token');
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: violetDark),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
