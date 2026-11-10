import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/download_helper.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class QrCodeDialog extends StatelessWidget {
  final StorageService storageService;

  const QrCodeDialog({super.key, required this.storageService});

  String _getAccessUrl() {
    final accessKey = storageService.config.accessKey;
    return DownloadHelper.buildAccessUrl(accessKey);
  }

  void _printQr() {
    DownloadHelper.openUrl('tarjeta_mesa_qr.html');
  }

  void _downloadPdf() {
    DownloadHelper.openUrl('tarjeta_mesa_qr.pdf');
  }

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.sageDark,
        content: const Text('¡Enlace con llave de acceso copiado al portapapeles! 🌸'),
      ),
    );
  }

  void _shareWhatsApp(String url) {
    final message = Uri.encodeComponent(
      '👑✨ ¡Hola! Entra aquí para subir y compartir tus fotos y videos en los 15 Años de Danna Alejandra: $url',
    );
    DownloadHelper.openUrl('https://api.whatsapp.com/send?text=$message');
  }

  @override
  Widget build(BuildContext context) {
    final qrAccessUrl = _getAccessUrl();
    final isMobile = MediaQuery.of(context).size.width < 768;
    final accessKey = storageService.config.accessKey;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 480,
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
            // Cabecera Verde Salvia & Rosado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.softPinkBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.pinkBorder),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.dustyPink, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código QR para Compartir',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.sageDeep,
                            ),
                          ),
                          Text(
                            'Clave de acceso: $accessKey • Escanea o comparte',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
            ),

            // Tarjeta de mesa elegante en Verde Salvia y Rosado
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.sageBorder, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 34)),
                        const SizedBox(height: 6),
                        Text(
                          'Mis 15 Años • Danna Alejandra',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '¡Sube tus fotos a nuestro álbum de recuerdos!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Código QR renderizado
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.pinkBorder, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.blushPink.withAlpha(40),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrAccessUrl,
                            version: QrVersions.auto,
                            size: 195.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.sageDark,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.sageDeep,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.sageBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.key_rounded, size: 13, color: AppTheme.dustyPink),
                              const SizedBox(width: 5),
                              Text(
                                'Llave de acceso: $accessKey',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.sageDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Escanea con la cámara de tu teléfono para acceder y subir fotos sin límites.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.mutedText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Botón directo para compartir por WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _shareWhatsApp(qrAccessUrl),
                      icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Compartir por WhatsApp 📲',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón directo para imprimir tarjeta de mesa física
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _printQr,
                      icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
                      label: Text(
                        'Imprimir Tarjetas para Mesas (Físico) 🖨️',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sageDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyLink(context, qrAccessUrl),
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Copiar Enlace'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.sageDark,
                            side: const BorderSide(color: AppTheme.sageBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _downloadPdf,
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppTheme.deepRose),
                          label: const Text('Bajar PDF 📄'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.deepRose,
                            side: const BorderSide(color: AppTheme.pinkBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
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
