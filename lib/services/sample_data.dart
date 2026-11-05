import '../models/memory_folder.dart';
import '../models/memory_item.dart';

class SampleData {
  static List<MemoryFolder> getInitialMemories() {
    final now = DateTime.now();

    return [
      MemoryFolder(
        id: 'folder_fam_valenzuela',
        guestName: 'Familia Valenzuela (Papás y Hermanos)',
        comment:
            '¡Nuestra princesa cumple 15 años! Eres la luz y alegría de nuestra casa, Danna. Que Dios bendiga cada paso de tu vida y que esta noche mágica sea el inicio de una etapa llena de sueños cumplidos. ¡Te amamos con todo nuestro corazón! 👑💖✨',
        timestamp: now.subtract(const Duration(minutes: 45)),
        likes: 24,
        isSyncedToGoogle: true,
        photos: [
          MemoryItem(
            id: 'sample_photo_1',
            fileName: 'vals_danna.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 45)),
            caption: 'El vals de honor con papá',
            fileSize: 2450000,
          ),
          MemoryItem(
            id: 'sample_photo_2',
            fileName: 'vestido_quinceanera.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 44)),
            caption: 'Nuestra hermosa quinceañera lista para la fiesta',
            fileSize: 3100000,
          ),
          MemoryItem(
            id: 'sample_photo_3',
            fileName: 'pastel_15_anos.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1535141192574-5d4897c13136?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 42)),
            caption: 'El espectacular pastel de 15',
            fileSize: 1980000,
          ),
          MemoryItem(
            id: 'sample_photo_4',
            fileName: 'brindis_familia.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 40)),
            caption: 'Brindis familiar con nuestra reina',
            fileSize: 2800000,
          ),
        ],
      ),
      MemoryFolder(
        id: 'folder_amigas_cole',
        guestName: 'Amigas del Colegio (Las Inseparables)',
        comment:
            '¡¡DANNITA LA ROMPISTE EN LA PISTA!! 💖✨ Estás más hermosa que nunca con ese vestido. ¡El vals fue el más épico y no pensamos parar de bailar en toda la noche! Te amamos millones amiga. 📸🥂💃',
        timestamp: now.subtract(const Duration(minutes: 25)),
        likes: 19,
        isSyncedToGoogle: true,
        photos: [
          MemoryItem(
            id: 'sample_photo_5',
            fileName: 'selfie_chicas.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 25)),
            caption: 'Selfie del squad con la cumpleañera',
            fileSize: 2150000,
          ),
          MemoryItem(
            id: 'sample_photo_6',
            fileName: 'luces_pista.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 23)),
            caption: 'En la pista con todo el ambiente',
            fileSize: 1850000,
          ),
          MemoryItem(
            id: 'sample_photo_7',
            fileName: 'sparklers_fiesta.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(minutes: 20)),
            caption: 'Momento de las luces de bengala ✨',
            fileSize: 2900000,
          ),
        ],
      ),
      MemoryFolder(
        id: 'folder_tia_marcela',
        guestName: 'Tía Marcela, Carlos y Primos',
        comment:
            '¡Muchas felicidades a nuestra sobrina consentida! Parece mentira lo rápido que pasa el tiempo, aún recordamos cuando aprendías a caminar y hoy eres toda una señorita llena de luz y gracia. Que la felicidad de esta noche te acompañe por siempre. ¡Te queremos mucho! 🌹🥂',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
        likes: 15,
        isSyncedToGoogle: true,
        photos: [
          MemoryItem(
            id: 'sample_photo_8',
            fileName: 'recuerdo_tia.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 10)),
            caption: 'La decoración del salón quedó de ensueño',
            fileSize: 3200000,
          ),
          MemoryItem(
            id: 'sample_photo_9',
            fileName: 'mesa_dulces.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1505977484362-97217c9fb377?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 8)),
            caption: 'La mesa de postres deliciosa',
            fileSize: 2600000,
          ),
        ],
      ),
      MemoryFolder(
        id: 'folder_padrinos_brindis',
        guestName: 'Padrinos de Brindis (Héctor y Sofía)',
        comment:
            'Un verdadero honor haber sido elegidos como tus padrinos para esta fecha tan memorable. Que tus 15 años sean el preludio de un futuro colmado de triunfos, salud y alegría infinita. ¡Salud por Danna! 🥂✨💫',
        timestamp: now.subtract(const Duration(hours: 2)),
        likes: 12,
        isSyncedToGoogle: true,
        photos: [
          MemoryItem(
            id: 'sample_photo_10',
            fileName: 'copas_brindis.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(hours: 2)),
            caption: 'El brindis por la quinceañera',
            fileSize: 2100000,
          ),
          MemoryItem(
            id: 'sample_photo_11',
            fileName: 'centros_mesa.jpg',
            remoteUrl:
                'https://images.unsplash.com/photo-1469371670807-013ccf25f16a?auto=format&fit=crop&w=900&q=80',
            timestamp: now.subtract(const Duration(hours: 1, minutes: 55)),
            caption: 'Las rosas y centros de mesa tan elegantes',
            fileSize: 2750000,
          ),
        ],
      ),
    ];
  }
}

