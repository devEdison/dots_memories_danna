import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class AccessKeyDialog extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback onUnlocked;

  const AccessKeyDialog({
    super.key,
    required this.storageService,
    required this.onUnlocked,
  });

  @override
  State<AccessKeyDialog> createState() => _AccessKeyDialogState();
}

class _AccessKeyDialogState extends State<AccessKeyDialog> {
  final _keyController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _verifyKey() async {
    final text = _keyController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Por favor escribe la clave de acceso');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.storageService.unlockWithKey(text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onUnlocked();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.sageDark,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '¡Llave de acceso verificada! Ya puedes subir fotos 🌸📸',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Clave incorrecta. Revisa el código en tu mesa o escanea el QR.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 440,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
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
            // Cabecera Salvia & Rosado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.softPinkBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.pinkBorder),
                    ),
                    child: const Icon(Icons.lock_rounded, color: AppTheme.dustyPink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llave de Acceso',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        Text(
                          'Acceso exclusivo para invitados a los 15 de Danna',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.sageBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📲', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Si escaneaste el código QR de las mesas, tu acceso ya está activo automáticamente. Si entraste por un enlace manual, ingresa la clave de invitación:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.charcoal,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _keyController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Clave de Acceso (Ej. DANNA15)',
                      hintText: 'Ingresa la clave...',
                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.sageGreen),
                      errorText: _errorMessage,
                    ),
                    onSubmitted: (_) => _verifyKey(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sageGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Validar Acceso 🌸',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

