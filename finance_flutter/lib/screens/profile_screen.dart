import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await ApiService.getMe();
      setState(() { _user = user; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roleColor = switch (auth.role) {
      'ADMIN' => Colors.red,
      'ANALYST' => Colors.orange,
      _ => Colors.green,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: roleColor.withOpacity(0.2),
                  child: Text(
                    (auth.username ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(auth.username ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (_user != null)
                  Text(_user!.email,
                      style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                RoleBadge(auth.role ?? 'VIEWER'),
                const SizedBox(height: 28),

                // Permissions
                AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Permissions',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 14),
                        _PermRow('View dashboard & records', true),
                        _PermRow('Create & edit records', auth.isAnalyst),
                        _PermRow('Delete records', auth.isAdmin),
                        _PermRow('Manage users', auth.isAdmin),
                      ]),
                ),
                const SizedBox(height: 16),

                // Account info
                if (_user != null)
                  AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Account Info',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 14),
                          _InfoRow('Status', _user!.status,
                              _user!.status == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.grey),
                          _InfoRow('Role', _user!.role, roleColor),
                        ]),
                  ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                            (_) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ]),
            ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final String label;
  final bool allowed;
  const _PermRow(this.label, this.allowed);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(allowed ? Icons.check_circle : Icons.cancel,
          color: allowed ? Colors.green : Colors.red, size: 18),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(
              color: allowed ? Colors.white70 : Colors.grey, fontSize: 14)),
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _InfoRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    ]),
  );
}
