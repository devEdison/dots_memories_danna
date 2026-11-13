import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/appwrite_auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'festive_effects.dart';

class GatekeeperScreen extends StatefulWidget {
  final StorageService storageService;
  final AppwriteAuthService authService;

  const GatekeeperScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<GatekeeperScreen> createState() => _GatekeeperScreenState();
}

class _GatekeeperScreenState extends State<GatekeeperScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Formulario Invitado
  final _keyController = TextEditingController();
  String? _guestError;

  // Formulario Anfitrión (Appwrite)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _authError;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGuestUnlock() async {
    // Sanitizar entrada de código
    final entered = _keyController.text.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '').trim();
    if (entered.isEmpty) {
      setState(() => _guestError = 'Por favor ingresa tu código de acceso');
      return;
    }

    final success = await widget.storageService.unlockWithKey(entered);
    if (!success) {
      setState(() {
        _guestError = 'Código de acceso no válido. Verifica el código en tu tarjeta QR.';
      });
    }
  }

  Future<void> _handleHostLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _authError = 'Por favor completa tu correo y contraseña');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _authError = null;
    });

    final res = await widget.authService.login(
      config: widget.storageService.config,
      email: email,
      password: pass,
    );

    if (mounted) {
      setState(() {
        _isLoggingIn = false;
        if (res['success'] != true) {
          _authError = res['message'] as String? ?? 'Credenciales incorrectas';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo atmosférico Verde Salvia + Rosado + Dorado con destellos animados
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEBF3EC),
                  Color(0xFFF7FBF8),
                  Color(0xFFFCEFF3),
                  Color(0xFFFCF7E8),
                ],
              ),
            ),
          ),
          const QuinceAmbientBackdrop(particleCount: 28, opacityMultiplier: 0.9),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.goldBorder, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.sageGreen.withAlpha(45),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: AppTheme.warmGold.withAlpha(45),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const QuinceTopRibbon(height: 5),
                      // ENCABEZADO CON EFECTOS DE 15 AÑOS (SALVIA, ROSADO Y DORADO)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          border: Border(bottom: BorderSide(color: AppTheme.goldBorder)),
                        ),
                        child: Column(
                          children: [
                            // Corona animada con halo Dorado, Rosado y estrellas (aislado en RepaintBoundary)
                            RepaintBoundary(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('✨', style: TextStyle(fontSize: 18))
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .fade(begin: 0.35, end: 1.0, duration: 1400.ms)
                                      .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.2, 1.2)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFFFFF),
                                          Color(0xFFFDF2F4),
                                          Color(0xFFFCF7E3),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.warmGold, width: 2.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.warmGold.withAlpha(80),
                                          blurRadius: 20,
                                          spreadRadius: 1,
                                        ),
                                        BoxShadow(
                                          color: AppTheme.blushPink.withAlpha(55),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: const Text('👑', style: TextStyle(fontSize: 34)),
                                  )
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.09, 1.09), duration: 2200.ms)
                                      .shimmer(duration: 2400.ms, color: AppTheme.goldLight),
                                  const SizedBox(width: 12),
                                  const Text('✨', style: TextStyle(fontSize: 18))
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .fade(begin: 1.0, end: 0.35, duration: 1400.ms)
                                      .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.85, 0.85)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Título de Danna con efecto Shimmer Dorado y Rosado (aislado en RepaintBoundary)
                            RepaintBoundary(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Mis 15 Años • ',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.sageDeep,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Danna Alejandra 🌸',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.deepRose,
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.warmGold.withAlpha(85),
                                            blurRadius: 7,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(duration: 2600.ms, color: AppTheme.goldLight),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(height: 1.2, width: 32, color: AppTheme.goldBorder),
                                const SizedBox(width: 8),
                                const Text('🌿 ✨ 🌸 ✨ 🌿', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 8),
                                Container(height: 1.2, width: 32, color: AppTheme.goldBorder),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Insignia oficial de Fecha del Evento
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.goldBorder, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.warmGold.withAlpha(30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 14,
                                    color: AppTheme.sageDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '28 de Noviembre de 2026',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      color: AppTheme.sageDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Álbum Digital de Recuerdos • Dots Memories ✨',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // SELECTOR DE PESTAÑAS: INVITADO QR vs ANFITRIÓN APPWRITE
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight.withAlpha(110),
                          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppTheme.warmGold,
                          indicatorWeight: 3,
                          labelColor: AppTheme.sageDeep,
                          unselectedLabelColor: AppTheme.mutedText,
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.celebration_rounded, size: 20, color: AppTheme.dustyPink),
                              text: 'Invitados (QR)',
                            ),
                            Tab(
                              icon: Icon(Icons.admin_panel_settings_rounded, size: 20, color: AppTheme.sageDark),
                              text: 'Anfitrión',
                            ),
                          ],
                        ),
                      ),

                      // CONTENIDO DE PESTAÑAS
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 335,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // 1. PESTAÑA INVITADO CON QR O CLAVE
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.warmGold, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Acceso para Invitados 🌸',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.sageDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ingresa el código de tu tarjeta QR para entrar a tu espacio privado donde podrás subir tus fotos, videos y dedicatoria para Danna Alejandra.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextField(
                                    controller: _keyController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      labelText: 'Código de Invitado',
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.sageGreen),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                      errorText: _guestError,
                                    ),
                                    onSubmitted: (_) => _handleGuestUnlock(),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: QuincePrimaryButton(
                                      onPressed: _handleGuestUnlock,
                                      icon: Icons.lock_open_rounded,
                                      label: 'Entrar a Mi Espacio de Recuerdos ✨',
                                      minHeight: 50,
                                      borderRadius: 16,
                                    ),
                                  ),
                                ],
                              ),

                              // 2. PESTAÑA ANFITRIÓN (INICIO DE SESIÓN APPWRITE)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.shield_rounded, color: AppTheme.sageDark, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Galería General (Anfitrión) 👑',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.sageDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Acceso para Danna Alejandra y su familia mediante autenticación segura.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Correo de anfitrión',
                                      hintText: 'correo@ejemplo.com',
                                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.sageGreen),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña de Appwrite',
                                      hintText: '••••••••',
                                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.sageGreen),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    onSubmitted: (_) => _handleHostLogin(),
                                  ),
                                  if (_authError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _authError!,
                                      style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: QuincePrimaryButton(
                                      onPressed: _isLoggingIn ? null : _handleHostLogin,
                                      leading: _isLoggingIn
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                      label: _isLoggingIn ? 'Verificando...' : 'Iniciar Sesión (Página Principal)',
                                      minHeight: 50,
                                      borderRadius: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
                    const SizedBox(height: 18),
                    const QuinceCopyrightNotice(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
