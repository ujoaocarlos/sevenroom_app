import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  String _nameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateName);
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      final value = _nameController.text;
      if (value.isEmpty) {
        _nameError = 'Digite seu nome completo';
      } else if (value.trim().split(' ').length < 2) {
        _nameError = 'Digite seu nome e sobrenome';
      } else {
        _nameError = '';
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final value = _emailController.text;
      if (value.isEmpty) {
        _emailError = 'Digite seu e-mail';
      } else if (!value.contains('@') || !value.contains('.')) {
        _emailError = 'E-mail inválido';
      } else if (!value.endsWith('.edu.br') && !value.contains('@aluno.')) {
        _emailError = 'Use seu e-mail institucional';
      } else {
        _emailError = '';
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final value = _passwordController.text;
      if (value.isEmpty) {
        _passwordError = 'Digite sua senha';
      } else if (value.length < 6) {
        _passwordError = 'Senha deve ter no mínimo 6 caracteres';
      } else {
        _passwordError = '';
      }
      _validateConfirmPassword();
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      final value = _confirmPasswordController.text;
      if (value.isNotEmpty && value != _passwordController.text) {
        _confirmPasswordError = 'As senhas não coincidem';
      } else if (value.isEmpty && _passwordController.text.isNotEmpty) {
        _confirmPasswordError = 'Confirme sua senha';
      } else {
        _confirmPasswordError = '';
      }
    });
  }

  Future<void> _handleRegister() async {
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    if (_nameError.isNotEmpty ||
        _emailError.isNotEmpty ||
        _passwordError.isNotEmpty ||
        _confirmPasswordError.isNotEmpty) {
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos de uso'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.registerWithEmail(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado! Faça login.'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _socialRegister(String provider) async {
    setState(() => _isLoading = true);
    try {
      User? user;
      if (provider == 'Google') {
        user = await _auth.signInWithGoogle();
      } else if (provider == 'Microsoft') {
        user = await _auth.signInWithMicrosoft();
      }
      if (mounted && user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadastro com $provider realizado!'), backgroundColor: AppColors.success),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? AppColors.darkBg : AppTheme.neutral50;
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final subtitleColor = isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral400;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;
    final errorStyle = const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Gradient Section with Curved Bottom ──
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipPath(
                    clipper: BottomOvalClipper(),
                    child: Container(
                      height: 240,
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
                    top: 50,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                color: AppColors.primaryBlue, size: 30),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Criar Conta',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cadastre-se para agendar salas',
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
                  ),
                ],
              ),

              // ── Form Card Container ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            boxShadow: isDarkMode
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
                              children: [
                                // Nome
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nome completo',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    errorText: _nameError.isNotEmpty ? _nameError : null,
                                    errorStyle: errorStyle,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // E-mail
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'E-mail institucional',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    errorText: _emailError.isNotEmpty ? _emailError : null,
                                    errorStyle: errorStyle,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Senha
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtitleColor),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    errorText: _passwordError.isNotEmpty ? _passwordError : null,
                                    errorStyle: errorStyle,
                                    helperText: 'Mínimo 6 caracteres',
                                    helperStyle: TextStyle(color: subtitleColor, fontSize: 11, fontFamily: 'Montserrat'),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Confirmar senha
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirmar senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: subtitleColor),
                                      onPressed: _togglePasswordVisibility,
                                    ),
                                    errorText: _confirmPasswordError.isNotEmpty ? _confirmPasswordError : null,
                                    errorStyle: errorStyle,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Termos de uso Checkbox
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                                        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : null),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: 'Montserrat'),
                                          children: [
                                            const TextSpan(text: 'Eu concordo com os '),
                                            TextSpan(
                                              text: 'Termos de Uso',
                                              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                                            ),
                                            const TextSpan(text: ' e '),
                                            TextSpan(
                                              text: 'Políticas',
                                              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Botão Cadastrar
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Text('Cadastrar'),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: borderColor)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('ou com', style: TextStyle(fontSize: 12, color: subtitleColor, fontFamily: 'Montserrat')),
                                    ),
                                    Expanded(child: Divider(color: borderColor)),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Botões sociais
                                Row(
                                  children: [
                                    Expanded(
                                      child: _socialBtn(
                                        'Google',
                                        Icons.g_mobiledata,
                                        isDarkMode,
                                        () => _socialRegister('Google'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _socialBtn(
                                        'Microsoft',
                                        Icons.window_rounded,
                                        isDarkMode,
                                        () => _socialRegister('Microsoft'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Link para voltar ao login
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text('Já tem uma conta? ', style: TextStyle(fontSize: 14, color: subtitleColor)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                              child: Text('Fazer login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'SevenRoom © 2026',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
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

  Widget _socialBtn(String label, IconData icon, bool isDarkMode, VoidCallback onTap) {
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final bgColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final textIconColor = isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textIconColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textIconColor, fontFamily: 'Montserrat')),
            ],
          ),
        ),
      ),
    );
  }
}