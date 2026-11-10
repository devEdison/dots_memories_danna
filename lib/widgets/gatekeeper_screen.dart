import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/appwrite_auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

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
  final _emailController = TextEditingController(text: 'admin@danna15.com');
  final _passwordController = TextEditingController(text: 'Danna15Memories');
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
    final entered = _keyController.text.trim();
    if (entered.isEmpty) {
      setState(() => _guestError = 'Por favor ingresa tu código de acceso');
      return;
    }

    final success = await widget.storageService.unlockWithKey(entered);
    if (!success) {
      setState(() {
        _guestError = 'Código de acceso no válido. Verifica el código en tu invitación QR.';
      });
    }
  }

  Future<void> _handleHostLogin() async {
    setState(() {
      _isLoggingIn = true;
      _authError = null;
    });

    final res = await widget.authService.login(
      config: widget.storageService.config,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoggingIn = false;
        if (res['success'] != true) {
          _authError = res['message'] as String? ?? 'Error al iniciar sesión';
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
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.borderLight, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.sageGreen.withAlpha(40),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ENCABEZADO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: const BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.pinkBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.dustyPink.withAlpha(40),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: const Text('👑', style: TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Mis 15 Años • Danna',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Álbum Privado de Recuerdos • Dots Memories',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SELECTOR DE PESTAÑAS: INVITADO QR vs ANFITRIÓN APPWRITE
                  Container(
                    color: AppTheme.sageLight.withAlpha(80),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.sageDark,
                      indicatorWeight: 3,
                      labelColor: AppTheme.sageDeep,
                      unselectedLabelColor: AppTheme.mutedText,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.qr_code_2_rounded, size: 20),
                          text: 'Invitados (QR)',
                        ),
                        Tab(
                          icon: Icon(Icons.admin_panel_settings_rounded, size: 20),
                          text: 'Anfitrión (Appwrite)',
                        ),
                      ],
                    ),
                  ),

                  // CONTENIDO DE PESTAÑAS
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 1. PESTAÑA INVITADO CON QR O CLAVE
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Acceso para Invitados 🌸',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageDeep,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ingresa el código que viene impreso en tu tarjeta QR o escanea el código con tu celular para entrar a tu espacio aislado de fotos y videos.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _keyController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Código de Invitado (Ej: DANNA15)',
                                  prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.sageGreen),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  errorText: _guestError,
                                ),
                                onSubmitted: (_) => _handleGuestUnlock(),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _handleGuestUnlock,
                                  icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                                  label: Text(
                                    'Entrar a Mi Espacio de Fotos',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.sageDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // 2. PESTAÑA ANFITRIÓN (INICIO DE SESIÓN APPWRITE)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Iniciar Sesión en Galería General 🔑',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageDeep,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Acceso para Danna y su familia mediante el sistema de autenticación de Appwrite.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.sageGreen),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Contraseña de Appwrite',
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoggingIn ? null : _handleHostLogin,
                                  icon: _isLoggingIn
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.login_rounded, color: Colors.white),
                                  label: Text(
                                    _isLoggingIn ? 'Verificando con Appwrite...' : 'Iniciar Sesión (Página Principal)',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.sageDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}

