import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/download_helper.dart';
import '../theme/app_theme.dart';

class QrCodeDialog extends StatelessWidget {
  const QrCodeDialog({super.key});

  String _getCurrentUrl() {
    return DownloadHelper.getCurrentUrl();
  }

  void _printQr() {
    DownloadHelper.printPage();
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _getCurrentUrl();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 460,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withAlpha(50),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabecera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📲', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Código QR para Mesas',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.deepPlum,
                        ),
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

            // Tarjeta imprimible de mesa
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.softBlush,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryRose.withAlpha(80), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 8),
                        Text(
                          'Mis 15 Años • Danna',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Comparte tus fotos con nosotros!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.mutedText,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Código QR renderizado
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: qrUrl,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppTheme.primaryDarkRose,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppTheme.deepPlum,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Abre la cámara de tu teléfono y escanea este código para subir tus recuerdos a la fiesta',
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

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _printQr,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Imprimir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Listo'),
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
