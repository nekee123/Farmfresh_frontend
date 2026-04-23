import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/profile/consumer_my_profile_screen.dart';
import '../screens/profile/farmer_my_profile_screen.dart';
// Admin profile screen would go here when created
// import '../screens/profile/admin_profile_screen.dart';

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'edit_profile':
            if (authService.isBuyer()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConsumerMyProfileScreen(),
                ),
              );
            } else if (authService.isSeller()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FarmerMyProfileScreen(),
                ),
              );
            } else if (authService.isAdmin()) {
              // Admin profile would go here when created
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin profile coming soon!')),
              );
            }
            break;
          case 'logout':
            _showLogoutDialog(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit_profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Edit Profile'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Log Out'),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
