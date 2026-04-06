import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'users_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final tabs = [
      const DashboardScreen(),
      const RecordsScreen(),
      if (auth.isAdmin) const UsersScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Records'),
      if (auth.isAdmin)
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
    ];

    // Guard index in case tabs shrink (e.g. role change)
    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        titleSpacing: 12,
        title: Row(children: [
          const Icon(Icons.account_balance_wallet, color: Color(0xFF6366F1), size: 22),
          const SizedBox(width: 8),
          const Text('Finance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor(auth.role).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _roleColor(auth.role).withOpacity(0.5)),
            ),
            child: Text(auth.role ?? '',
                style: TextStyle(color: _roleColor(auth.role), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
              child: Text((auth.username ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
            onPressed: () async {
              await auth.logout();
              if (mounted) Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: tabs[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }

  Color _roleColor(String? role) => switch (role) {
    'ADMIN' => Colors.red,
    'ANALYST' => Colors.orange,
    _ => Colors.green,
  };
}
