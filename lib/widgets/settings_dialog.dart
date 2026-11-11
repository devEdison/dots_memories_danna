import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_config.dart';
import '../services/download_helper.dart';
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
  late TextEditingController _keyController;
  late bool _useGoogle;
  late bool _requireKey;
  bool _isTesting = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final config = widget.storageService.config;
    _urlController = TextEditingController(text: config.googleScriptUrl);
    _keyController = TextEditingController(text: config.accessKey);
    _useGoogle = config.useGoogleBackend;
    _requireKey = config.requireAccessKey;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
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
      accessKey: _keyController.text.trim().isEmpty ? 'DANNA15' : _keyController.text.trim().toUpperCase(),
      requireAccessKey: _requireKey,
    );

    final saved = await widget.storageService.saveConfig(updated, requireAdmin: true);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Configuración guardada correctamente 🌸'
                : 'Acción no autorizada: inicia sesión como anfitrión.',
          ),
          backgroundColor: saved ? AppTheme.sageDark : const Color(0xFFB91C1C),
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
      SnackBar(
        content: const Text('¡Código de Google Apps Script copiado al portapapeles! 🌸'),
        backgroundColor: AppTheme.sageGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final currentInviteUrl = DownloadHelper.buildAccessUrl(_keyController.text.trim());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: isMobile ? double.infinity : 660,
        constraints: const BoxConstraints(maxHeight: 740),
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
          children: [
            // Header Verde Salvia & Rosado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
                    child: const Icon(Icons.tune_rounded, color: AppTheme.sageDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajustes & Llave de Acceso',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.sageDeep,
                          ),
                        ),
                        Text(
                          'Control de subidas, clave QR y Google Nube',
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
                    // SECCIÓN 1: LLAVE DE ACCESO QR
                    Text(
                      '🔑 LLAVE DE ACCESO EXCLUSIVA',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: AppTheme.sageDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.softPinkBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.pinkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exigir llave de acceso para subir fotos',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.sageDeep,
                                      ),
                                    ),
                                    Text(
                                      'Solo quienes escaneen el QR con la URL autorizada podrán subir fotos.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.mutedText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _requireKey,
                                activeThumbColor: AppTheme.dustyPink,
                                onChanged: (val) => setState(() => _requireKey = val),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _keyController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Clave de Acceso (se incluye en el QR)',
                              hintText: 'Clave personalizada...',
                              prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.dustyPink),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'URL con llave: $currentInviteUrl',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.sageDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                tooltip: 'Copiar enlace con llave',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: currentInviteUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enlace copiado al portapapeles')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECCIÓN 2: GOOGLE DRIVE / FOTOS
                    Text(
                      '☁️ ALMACENAMIENTO GOOGLE FOTOS / DRIVE',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: AppTheme.sageDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tarjeta del Álbum de Google Fotos Vinculado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.softPinkBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.pinkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Álbum Oficial de Danna en Google Fotos',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.sageDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => DownloadHelper.openUrl(
                              widget.storageService.config.googlePhotosAlbumUrl,
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            label: const Text('Abrir Álbum en Google Fotos'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dustyPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tarjeta de Carpeta Principal en Google Drive
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.sageBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_shared_rounded, color: AppTheme.sageDark, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Carpeta Principal en Google Drive',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.sageDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ruta: Mi Unidad > 15 Años Danna - Fotos de Invitados',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sageDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.storageService.config.googleDriveFolderUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () => DownloadHelper.openUrl(
                              widget.storageService.config.googleDriveFolderUrl,
                            ),
                            icon: const Icon(Icons.open_in_new_rounded, size: 15),
                            label: const Text('Abrir Carpeta en Google Drive'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.sageDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.sageBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Subir a Google Drive / Fotos',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.sageDeep,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Crea carpetas por invitado en tu Google Drive sin costo alguno.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useGoogle,
                            activeThumbColor: AppTheme.sageGreen,
                            onChanged: (val) => setState(() => _useGoogle = val),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL de Google Apps Script Web App',
                        hintText: 'https://script.google.com/macros/s/.../exec',
                        prefixIcon: const Icon(Icons.cloud_upload_outlined, color: AppTheme.sageGreen),
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
                            foregroundColor: AppTheme.sageDark,
                            side: const BorderSide(color: AppTheme.sageBorder),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _copyScriptCode,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copiar Script'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.sageDark,
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

                    const SizedBox(height: 20),

                    // Explicación paso a paso
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        '📖 ¿Cómo instalar el script de Google en 2 min?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.sageDark,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStep(1, 'Entra a script.google.com y haz clic en "Nuevo proyecto".'),
                              _buildStep(2, 'Pulsa "Copiar Script" arriba y pega el código en el editor.'),
                              _buildStep(3, 'Haz clic en Implementar > Nueva implementación > Tipo: Aplicación web.'),
                              _buildStep(4, 'En "Quién tiene acceso" selecciona: "Cualquiera".'),
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
                                color: AppTheme.sageDeep,
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
                            final resetOk = await widget.storageService.resetToDemo();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    resetOk
                                        ? 'Recuerdos de demo restaurados'
                                        : 'Acción no autorizada: solo el anfitrión.',
                                  ),
                                ),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.sageGreen),
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
              color: AppTheme.sageLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.sageDark,
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
