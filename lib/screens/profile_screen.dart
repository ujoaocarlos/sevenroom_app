import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool currentDarkMode;
  const ProfileScreen({super.key, required this.onThemeToggle, required this.currentDarkMode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _auth.getUserData();
    setState(() {
      userData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nome'),
                      subtitle: Text(userData?['nome'] ?? ''),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('E-mail'),
                      subtitle: Text(userData?['email'] ?? ''),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings),
                      title: const Text('Tipo de usuário'),
                      subtitle: Text(userData?['role'] == 'admin' ? 'Administrador' : 'Usuário comum'),
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Tema escuro'),
                    secondary: const Icon(Icons.dark_mode),
                    value: widget.currentDarkMode,
                    onChanged: widget.onThemeToggle,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
    );
  }
}