import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final users = await ApiService.getUsers();
      setState(() { _users = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ]))
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(children: [
                      Text('${_users.length} user${_users.length != 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const Spacer(),
                      // Role summary badges
                      ..._roleSummary(),
                    ]),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _UserTile(
                          user: _users[i],
                          onUpdate: (role, status) => _update(_users[i], role, status),
                        ),
                      ),
                    ),
                  ),
                ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _showRegisterDialog,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  List<Widget> _roleSummary() {
    final counts = {'ADMIN': 0, 'ANALYST': 0, 'VIEWER': 0};
    for (final u in _users) counts[u.role] = (counts[u.role] ?? 0) + 1;
    return counts.entries.map((e) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text('${e.value} ${e.key.toLowerCase()}',
          style: TextStyle(color: _roleColor(e.key), fontSize: 11)),
    )).toList();
  }

  Future<void> _update(User user, String? role, String? status) async {
    try {
      final res = await ApiService.updateUser(user.id, {
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      });
      if (res['success'] == true) {
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated'), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showRegisterDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add New User', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(usernameCtrl, 'Username', false,
                validator: (v) => v!.length < 3 ? 'Min 3 characters' : null),
            const SizedBox(height: 12),
            _dialogField(emailCtrl, 'Email', false,
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
            const SizedBox(height: 12),
            _dialogField(passwordCtrl, 'Password', true,
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final res = await ApiService.register(
                  usernameCtrl.text.trim(), emailCtrl.text.trim(), passwordCtrl.text);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (res['success'] == true) {
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User created'), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'] ?? 'Failed'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, bool obscure,
      {String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl, obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.grey),
          filled: true, fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        validator: validator,
      );

  Color _roleColor(String role) => switch (role) {
    'ADMIN' => Colors.red,
    'ANALYST' => Colors.orange,
    _ => Colors.green,
  };
}

class _UserTile extends StatelessWidget {
  final User user;
  final Function(String? role, String? status) onUpdate;
  const _UserTile({required this.user, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final roleColor = switch (user.role) {
      'ADMIN' => Colors.red,
      'ANALYST' => Colors.orange,
      _ => Colors.green,
    };
    final isActive = user.status == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.3)),
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: isActive ? roleColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Text(user.username[0].toUpperCase(),
              style: TextStyle(color: isActive ? roleColor : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(user.username,
                style: TextStyle(color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600)),
            if (!isActive) ...[
              const SizedBox(width: 6),
              const Text('(inactive)', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ]),
          Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            _Badge(user.role, roleColor),
            const SizedBox(width: 8),
            _Badge(user.status, isActive ? Colors.green : Colors.grey),
          ]),
        ])),
        PopupMenuButton<String>(
          color: const Color(0xFF0F172A),
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (v) {
            if (v == 'deactivate') onUpdate(null, 'INACTIVE');
            else if (v == 'activate') onUpdate(null, 'ACTIVE');
            else onUpdate(v, null);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'VIEWER',
                child: Row(children: [Icon(Icons.visibility, color: Colors.green, size: 18),
                  SizedBox(width: 8), Text('Set Viewer', style: TextStyle(color: Colors.white))])),
            const PopupMenuItem(value: 'ANALYST',
                child: Row(children: [Icon(Icons.analytics, color: Colors.orange, size: 18),
                  SizedBox(width: 8), Text('Set Analyst', style: TextStyle(color: Colors.white))])),
            const PopupMenuItem(value: 'ADMIN',
                child: Row(children: [Icon(Icons.admin_panel_settings, color: Colors.red, size: 18),
                  SizedBox(width: 8), Text('Set Admin', style: TextStyle(color: Colors.white))])),
            const PopupMenuDivider(),
            if (isActive)
              const PopupMenuItem(value: 'deactivate',
                  child: Row(children: [Icon(Icons.block, color: Colors.red, size: 18),
                    SizedBox(width: 8), Text('Deactivate', style: TextStyle(color: Colors.red))]))
            else
              const PopupMenuItem(value: 'activate',
                  child: Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18),
                    SizedBox(width: 8), Text('Activate', style: TextStyle(color: Colors.green))])),
          ],
        ),
      ]),
    );
  }

  Widget _Badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11)),
  );
}
