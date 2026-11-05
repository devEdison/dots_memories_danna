import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_config.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  final StorageService storageService;

  const SettingsDialog({
    super.key,
    required this.storageService,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _urlController;
  late bool _useGoogle;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final config = widget.storageService.config;
    _urlController = TextEditingController(text: config.googleScriptUrl);
    _useGoogle = config.useGoogleBackend;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'Por favor pega la URL de la aplicación web de Google Apps Script.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final res = await widget.storageService.testGoogleConnection(url);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = res['success'] as bool;
        _testMessage = res['message'] as String;
      });
    }
  }

  Future<void> _save() async {
    final updated = AppConfig(
      googleScriptUrl: _urlController.text.trim(),
      useGoogleBackend: _useGoogle,
      eventTitle: widget.storageService.config.eventTitle,
      eventDate: widget.storageService.config.eventDate,
      quinceaneraName: widget.storageService.config.quinceaneraName,
    );

    await widget.storageService.saveConfig(updated);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _copyScriptCode() {
    const scriptCode = r'''const MAIN_FOLDER_NAME = "15 Años Danna - Fotos de Invitados";

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return responseJSON({ status: "error", message: "No se recibieron datos" });
    }
    const data = JSON.parse(e.postData.contents);
    const guestName = (data.guestName || "Invitado").trim();
    const comment = (data.comment || "").trim();
    const photos = data.photos || [];

    const mainFolder = getOrCreateMainFolder(MAIN_FOLDER_NAME);
    const now = new Date();
    const dateStr = Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "yyyy-MM-dd_HH-mm");
    const safeGuestName = guestName.replace(/[\/\\:*?"<>|]/g, "_");
    const guestFolder = mainFolder.createFolder(safeGuestName + " (" + dateStr + ")");
    guestFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    const note = "MIS 15 AÑOS - DANNA\nDe: " + guestName + "\nFecha: " + now.toLocaleString() + "\nMensaje: " + comment;
    guestFolder.createFile("Dedicatoria_" + safeGuestName + ".txt", note, "text/plain");

    const savedPhotos = [];
    for (var i = 0; i < photos.length; i++) {
      try {
        const item = photos[i];
        const decoded = Utilities.base64Decode(item.base64);
        const blob = Utilities.newBlob(decoded, item.type || "image/jpeg", item.name || ("foto_" + (i + 1) + ".jpg"));
        const file = guestFolder.createFile(blob);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        savedPhotos.push({
          name: file.getName(),
          id: file.getId(),
          url: "https://lh3.googleusercontent.com/d/" + file.getId(),
          viewUrl: file.getUrl()
        });
      } catch (err) {}
    }

    return responseJSON({
      status: "success",
      folderId: guestFolder.getId(),
      folderUrl: guestFolder.getUrl(),
      photosCount: savedPhotos.length,
      photos: savedPhotos
    });
  } catch (err) {
    return responseJSON({ status: "error", message: err.toString() });
  }
}

function doGet(e) {
  return responseJSON({ status: "ok", message: "Backend activo" });
}

function getOrCreateMainFolder(name) {
  const f = DriveApp.getFoldersByName(name);
  if (f.hasNext()) return f.next();
  const created = DriveApp.createFolder(name);
  created.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return created;
}

function responseJSON(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}''';

    Clipboard.setData(const ClipboardData(text: scriptCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Código de Google Apps Script copiado al portapapeles!'),
        backgroundColor: AppTheme.primaryRose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 640,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withAlpha(40),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_outlined, color: AppTheme.primaryRose),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Fotos & Nube',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepPlum,
                          ),
                        ),
                        Text(
                          'Almacena fotos sin costo y organízalas por carpetas de invitado',
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
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                  ),
                ],
              ),
            ),

            // Contenido Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Switch Google Fotos / Drive
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.softBlush,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subir a Google Drive / Google Fotos',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.deepPlum,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Las fotos se guardan automáticamente en tu Google Drive dentro de una carpeta por cada invitado.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useGoogle,
                            activeThumbColor: AppTheme.primaryRose,
                            onChanged: (val) => setState(() => _useGoogle = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Campo de URL del Script
                    Text(
                      'URL de Google Apps Script Web App',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.deepPlum,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'https://script.google.com/macros/s/.../exec',
                        prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primaryRose),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded, size: 20),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data != null && data.text != null) {
                              _urlController.text = data.text!;
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botón probar conexión
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering_rounded, size: 16),
                          label: Text(_isTesting ? 'Probando...' : 'Probar Conexión'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _copyScriptCode,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copiar Script'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryDarkRose,
                            textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    if (_testMessage != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testSuccess == true ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _testSuccess == true ? const Color(0xFF81C784) : const Color(0xFFE57373),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _testSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded,
                              size: 18,
                              color: _testSuccess == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testMessage!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _testSuccess == true ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Explicación paso a paso
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        '📖 ¿Cómo crear el script de Google en 2 minutos?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryRose,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStep(1, 'Entra a script.google.com y haz clic en "Nuevo proyecto".'),
                              _buildStep(2, 'Haz clic en el botón "Copiar Script" arriba y pega el código en el editor.'),
                              _buildStep(3, 'Haz clic en Implementar > Nueva implementación > Tipo: Aplicación web.'),
                              _buildStep(4, 'En "Quién tiene acceso" selecciona: "Cualquiera" (para que tus invitados suban sin login).'),
                              _buildStep(5, 'Copia la URL que termina en /exec y pégala aquí.'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Restablecer demostración
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recuerdos de demostración',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.deepPlum,
                              ),
                            ),
                            Text(
                              'Carga datos de prueba de los 15 de Danna',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            await widget.storageService.resetToDemo();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Recuerdos de demo restaurados')),
                              );
                            }
                          },
                          child: const Text('Restaurar Demo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botón Guardar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Guardar Cambios'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.softBlush,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRose,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.charcoal, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
