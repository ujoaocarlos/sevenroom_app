import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../services/auth_services.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  bool _isAdmin = false;
  bool _loading = true;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _checkAdmin();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final admin = await _auth.isAdmin();
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _loading = false;
    });
    _fadeCtrl.forward();
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppTheme.neutral50;
    final textColor = isDark ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor = isDark ? const Color(0xFF9E99B5) : AppTheme.neutral400;

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final greeting = _getGreeting();

    final List<_MenuItem> items = [
      _MenuItem(
        title: 'Reservar Sala',
        subtitle: 'Escolha e agende um espaço disponível para o seu evento ou reunião.',
        icon: Icons.meeting_room_outlined,
        gradient: const LinearGradient(
          colors: [AppColors.deepBlue, AppColors.skyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/rooms',
      ),
      _MenuItem(
        title: 'Minhas Reservas',
        subtitle: 'Acompanhe o status de todas as suas reservas e agendamentos.',
        icon: Icons.calendar_month_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF5B2DE0), Color(0xFF9B59E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/my_reservations',
      ),
      _MenuItem(
        title: 'Salas Disponíveis',
        subtitle: 'Veja em tempo real quais espaços estão livres agora.',
        icon: Icons.list_alt_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF1A8A5A), Color(0xFF2AA275)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/rooms',
      ),
      if (_isAdmin)
        _MenuItem(
          title: 'Painel Admin',
          subtitle: 'Gerencie salas, usuários e aprovações de reservas.',
          icon: Icons.admin_panel_settings_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFB07A00), Color(0xFFFCB900)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          route: '/admin',
        ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Curved Top Gradient Header ──
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.deepBlue, AppColors.skyBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Avatar with initial letter
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  _capitalize(widget.userName).isNotEmpty
                                      ? _capitalize(widget.userName)[0]
                                      : '?',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(greeting,
                                      style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _capitalize(widget.userName),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_isAdmin) ...[
                                    const SizedBox(height: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Administrador',
                                          style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _headerActionBtn(
                        icon: Icons.person_outline_rounded,
                        tooltip: 'Meu Perfil',
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                ),

                // ── Section Title ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                  child: Text(
                    'O que você deseja fazer?',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: subtitleColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // ── Vertical Menu Cards ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      ...items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return _AnimatedMenuCard(
                          item: item,
                          delay: Duration(milliseconds: 80 * i),
                          isDark: isDark,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          onTap: () => Navigator.pushNamed(context, item.route),
                        );
                      }),
                    ],
                  ),
                ),

                // ── Logout ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _LogoutCard(onTap: _logout, isDark: isDark),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'SevenRoom • Versão 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia,';
    if (h < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ── Data class ──
class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String route;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
  });
}

// ── Animated vertical card with staggered entrance ──
class _AnimatedMenuCard extends StatefulWidget {
  final _MenuItem item;
  final Duration delay;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _AnimatedMenuCard({
    required this.item,
    required this.delay,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  State<_AnimatedMenuCard> createState() => _AnimatedMenuCardState();
}

class _AnimatedMenuCardState extends State<_AnimatedMenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? AppColors.darkSurface : Colors.white;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : const Color(0xFFE8EAED);

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: IntrinsicHeight(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: widget.isDark ? 0.25 : 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left gradient strip + icon
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          gradient: widget.item.gradient,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Icon(widget.item.icon,
                              color: Colors.white, size: 32),
                        ),
                      ),
                    // Text content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: widget.textColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.item.subtitle,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.subtitleColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            size: 13, color: widget.subtitleColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

// ── Logout card ──
class _LogoutCard extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _LogoutCard({required this.onTap, required this.isDark});

  @override
  State<_LogoutCard> createState() => _LogoutCardState();
}

class _LogoutCardState extends State<_LogoutCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? AppColors.darkSurface : Colors.white;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : const Color(0xFFE8EAED);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 14),
              const Text(
                'Sair da conta',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.error.withValues(alpha: 0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
