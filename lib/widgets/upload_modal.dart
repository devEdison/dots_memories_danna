import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class UploadModal extends StatefulWidget {
  final StorageService storageService;

  const UploadModal({
    super.key,
    required this.storageService,
  });

  @override
  State<UploadModal> createState() => _UploadModalState();
}

class _UploadModalState extends State<UploadModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();

  final List<SelectedFile> _selectedFiles = [];
  bool _isPicking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result.isNotEmpty) {
        for (final file in result) {
          final bytes = await file.readAsBytes();
          final size = (await file.length()) ?? bytes.length;

          // Determinar mimeType básico
          String mime = 'image/jpeg';
          final ext = file.extension?.toLowerCase();
          if (ext == 'png') mime = 'image/png';
          if (ext == 'webp') mime = 'image/webp';
          if (ext == 'heic') mime = 'image/heic';

          _selectedFiles.add(
            SelectedFile(
              name: file.name,
              bytes: bytes,
              size: size,
              mimeType: mime,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seleccionando fotos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos una foto para subir 📸'),
          backgroundColor: AppTheme.primaryRose,
        ),
      );
      return;
    }

    final success = await widget.storageService.uploadMemories(
      guestName: _nameController.text,
      comment: _commentController.text,
      files: List.from(_selectedFiles),
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2E7D32),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Tus fotos y dedicatoria han sido guardadas con éxito para Danna! 👑💖',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un inconveniente al procesar las fotos.'),
          ),
        );
      }
    }
  }

  String _formatTotalSize() {
    int totalBytes = 0;
    for (final f in _selectedFiles) {
      totalBytes += f.size;
    }
    final mb = totalBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return ValueListenableBuilder<bool>(
      valueListenable: widget.storageService.isUploadingNotifier,
      builder: (context, isUploading, child) {
        return PopScope(
          canPop: !isUploading,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 36,
              vertical: isMobile ? 16 : 36,
            ),
            child: Container(
              width: isMobile ? double.infinity : 680,
              constraints: BoxConstraints(maxHeight: size.height * 0.92),
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
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Encabezado
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
                              child: const Text('✨', style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subir Recuerdos para Danna',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.deepPlum,
                                    ),
                                  ),
                                  Text(
                                    'Comparte todas las fotos que tomaste y tu dedicatoria',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isUploading)
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(backgroundColor: Colors.white),
                              ),
                          ],
                        ),
                      ),

                      // Formulario scrollable
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 18 : 26),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre del invitado
                                Text(
                                  'Tu Nombre o Familia *',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.deepPlum,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  enabled: !isUploading,
                                  decoration: InputDecoration(
                                    hintText: 'Ej. Tía Carmen y Familia, Amigos de la escuela...',
                                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryRose),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Por favor escribe tu nombre para que Danna sepa quién lo subió';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Dedicatoria
                                Text(
                                  'Dedicatoria o Mensaje para Danna',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.deepPlum,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _commentController,
                                  enabled: !isUploading,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: '¡Escribe aquí tus mejores deseos, anécdotas de la fiesta o un mensaje con todo tu cariño! 💕',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 40),
                                      child: Icon(Icons.message_rounded, color: AppTheme.primaryRose),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // Zona de selección de fotos
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fotos del Evento (${_selectedFiles.length})',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.deepPlum,
                                      ),
                                    ),
                                    if (_selectedFiles.isNotEmpty)
                                      Text(
                                        'Peso total: ${_formatTotalSize()}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Dropzone clickeable
                                InkWell(
                                  onTap: isUploading || _isPicking ? null : _pickPhotos,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softBlush,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primaryRose.withAlpha(120),
                                        width: 1.8,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryRose.withAlpha(30),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 32,
                                            color: AppTheme.primaryRose,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _isPicking
                                              ? 'Abriendo galería...'
                                              : 'Toca aquí para elegir fotos',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryDarkRose,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '¡Puedes seleccionar todas las fotos que quieras a la vez! Sin límite.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.mutedText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Lista de fotos seleccionadas con miniaturas y botón eliminar
                                if (_selectedFiles.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Fotos listas para subir:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: isUploading ? null : _pickPhotos,
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Agregar más'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryRose,
                                          textStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedFiles.length,
                                      itemBuilder: (context, index) {
                                        final file = _selectedFiles[index];
                                        return Container(
                                          width: 100,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.borderLight),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image.memory(
                                                file.bytes,
                                                fit: BoxFit.cover,
                                              ),
                                              // Botón eliminar foto individual
                                              if (!isUploading)
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: InkWell(
                                                    onTap: () => _removeFile(index),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xB3000000),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 28),

                                // BOTÓN DE ENVÍO
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isUploading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryRose,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                                        const SizedBox(width: 10),
                                        Text(
                                          _selectedFiles.isEmpty
                                              ? 'Selecciona fotos para continuar'
                                              : 'Crear Carpeta y Subir Fotos (${_selectedFiles.length})',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
                    ],
                  ),

                  // Overlay animado de progreso de subida
                  if (isUploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withAlpha(240),
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.softBlush,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryRose.withAlpha(40),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_rounded,
                                  size: 48,
                                  color: AppTheme.primaryRose,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Guardando recuerdos para Danna...',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.deepPlum,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ValueListenableBuilder<String>(
                                valueListenable: widget.storageService.uploadStatusNotifier,
                                builder: (context, status, _) {
                                  return Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.mutedText,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 280,
                                child: ValueListenableBuilder<double>(
                                  valueListenable: widget.storageService.uploadProgressNotifier,
                                  builder: (context, progress, _) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        minHeight: 8,
                                        backgroundColor: AppTheme.borderLight,
                                        color: AppTheme.primaryRose,
                                      ),
                                    );
                                  },
                                ),
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
      },
    );
  }
}
