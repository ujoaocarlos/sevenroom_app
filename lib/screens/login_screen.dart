import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _auth.signInWithEmail(
            _emailController.text.trim(), _passwordController.text);
        if (mounted) {
          String userName = _emailController.text.trim().split('@').first;
          Navigator.pushReplacementNamed(context, '/home', arguments: userName);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recuperar senha',
            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Digite seu e-mail institucional para receber o link de recuperação.',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final msg = ScaffoldMessenger.of(context);
              try {
                await _auth.sendPasswordResetEmail(emailController.text.trim());
                if (!nav.mounted) return;
                nav.pop();
                msg.showSnackBar(const SnackBar(
                    content: Text('Link de recuperação enviado!')));
              } catch (e) {
                if (!nav.mounted) return;
                msg.showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _socialLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      User? user;
      if (provider == 'Google') {
        user = await _auth.signInWithGoogle();
      } else if (provider == 'Microsoft') {
        user = await _auth.signInWithMicrosoft();
      }
      if (mounted && user != null) {
        String userName =
            user.displayName ?? user.email?.split('@').first ?? 'Usuário';
        Navigator.pushReplacementNamed(context, '/home', arguments: userName);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppTheme.errorColor));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppTheme.neutral50;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppTheme.neutral200;
    final subtitleColor = isDark ? const Color(0xFF9E99B5) : AppTheme.neutral400;
    final primary = isDark ? AppColors.skyBlue : AppTheme.primaryColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Gradient Section (Bottom Oval style from 7me portal) ──
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: BottomOvalClipper(),
                    child: Container(
                      height: 280,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.deepBlue, AppColors.skyBlue],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    child: Column(
                      children: [
                        // App Logo
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(Icons.meeting_room_rounded,
                              color: AppColors.primaryBlue, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SevenRoom',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Agendamento de salas universitárias',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Form Card Container ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Entrar na sua conta',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppTheme.neutral900,
                                    )),
                                const SizedBox(height: 4),
                                Text('Use suas credenciais institucionais',
                                    style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 13,
                                        color: subtitleColor)),
                                const SizedBox(height: 24),

                                // Email Input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail institucional',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Digite seu e-mail'
                                          : (!v.contains('@') ? 'E-mail inválido' : null),
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: subtitleColor,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Digite sua senha'
                                          : (v.length < 6 ? 'Mínimo 6 caracteres' : null),
                                ),

                                // Forget Password Link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      foregroundColor: primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 8),
                                    ),
                                    child: const Text('Esqueci minha senha',
                                        style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Login Button
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                color: Colors.white, strokeWidth: 2.5))
                                        : const Text('Entrar'),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                Row(children: [
                                  Expanded(
                                      child: Divider(color: borderColor)),
                                  Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('ou', style: TextStyle(color: subtitleColor, fontSize: 12, fontFamily: 'Montserrat'))),
                                  Expanded(child: Divider(color: borderColor)),
                                ]),
                                const SizedBox(height: 16),

                                // Social Buttons
                                Row(children: [
                                  Expanded(
                                      child: _socialBtn(
                                          'Google', Icons.g_mobiledata, isDark,
                                          () => _socialLogin('Google'))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _socialBtn(
                                          'Microsoft', Icons.window_rounded, isDark,
                                          () => _socialLogin('Microsoft'))),
                                ]),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Create Account Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text('Não tem uma conta? ',
                                style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: subtitleColor)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/register'),
                              child: Text('Criar conta',
                                  style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('SevenRoom © 2026',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                color: subtitleColor)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialBtn(
      String label, IconData icon, bool isDark, VoidCallback onTap) {
    final borderColor = isDark ? AppColors.darkBorder : AppTheme.neutral200;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E0EC) : AppTheme.neutral700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}

// ── Custom Clipper for bottom-oval shape inspired by 7me ──
class BottomOvalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 40);

    var firstControlPoint = Offset(size.width / 2, size.height);
    var firstEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
