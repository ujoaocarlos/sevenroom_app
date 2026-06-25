import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/auth_services.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _auth = AuthService();
  AppUser? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _auth.getUserData();
    if (!mounted) return;
    setState(() {
      _userData = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Card do perfil
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          (_userData?.nome ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData?.nome ?? 'Usuário',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppTheme.neutral900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData?.email ?? '',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              color: isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card de tema
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderColor),
              ),
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Aparência',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppTheme.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<AppThemeMode>(
                      initialValue: themeProvider.mode,
                      decoration: InputDecoration(
                        labelText: 'Tema',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? AppColors.darkBg : Colors.white,
                      ),
                      dropdownColor: isDarkMode ? AppColors.darkSurface : Colors.white,
                      items: const [
                        DropdownMenuItem(value: AppThemeMode.light, child: Text('Claro', style: TextStyle(fontFamily: 'Montserrat'))),
                        DropdownMenuItem(value: AppThemeMode.dark, child: Text('Escuro', style: TextStyle(fontFamily: 'Montserrat'))),
                        DropdownMenuItem(value: AppThemeMode.system, child: Text('Seguir sistema', style: TextStyle(fontFamily: 'Montserrat'))),
                      ],
                      onChanged: (value) {
                        if (value != null) themeProvider.setMode(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botão Sair
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showLogoutConfirmation,
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Sair da conta',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SevenRoom • Versão 1.0.0',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: isDarkMode ? const Color(0xFF6B6680) : AppTheme.neutral400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja sair?', style: TextStyle(fontFamily: 'Montserrat')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(fontFamily: 'Montserrat', color: isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}