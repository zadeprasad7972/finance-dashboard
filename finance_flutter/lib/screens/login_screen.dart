import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_widgets.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(children: [
                const Icon(Icons.account_balance_wallet,
                    size: 64, color: Color(0xFF6366F1)),
                const SizedBox(height: 16),
                const Text('Finance Dashboard',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Sign in to your account',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                AppTextField(
                  controller: _usernameCtrl,
                  label: 'Username',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                AppButton(
                    label: 'Sign In',
                    loading: auth.loading,
                    icon: Icons.login,
                    onPressed: _login),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Demo Accounts',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        _DemoRow('admin', 'admin123', 'ADMIN', Colors.red),
                        _DemoRow('analyst', 'analyst123', 'ANALYST',
                            Colors.orange),
                        _DemoRow('viewer', 'viewer123', 'VIEWER', Colors.green),
                      ]),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register",
                      style: TextStyle(color: Color(0xFF6366F1))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoRow extends StatelessWidget {
  final String username, password, role;
  final Color color;
  const _DemoRow(this.username, this.password, this.role, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8)),
        child: Text(role, style: TextStyle(color: color, fontSize: 11)),
      ),
      const SizedBox(width: 10),
      Text('$username / $password',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    ]),
  );
}
