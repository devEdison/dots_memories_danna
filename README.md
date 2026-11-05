# 👑 Mis 15 Años - Danna | Dots Memories (Flutter Web)

Una aplicación web moderna y elegante inspirada en **Dots Memories** diseñada específicamente para la celebración de los **15 años de Danna**. Permite a todos los invitados escanear un código QR en su mesa, subir **todas las fotos que deseen sin límite**, agregar su dedicatoria o mensaje con cariño, y organizar automáticamente todo en **carpetas identificadas por invitado**.

Las fotos se respaldan de forma directa en **Google Drive / Google Fotos** usando un webhook gratuito de **Google Apps Script**, resolviendo por completo cualquier problema o costo de almacenamiento.

---

## 📸 Características Principales

1. **Subida Masiva de Fotos**:
   - Selección múltiple de fotos (1, 10, 50, 100+ fotos a la vez sin límites artificiales).
   - Previsualización en tiempo real de miniaturas con peso total y opción de remover fotos individuales antes de enviar.
   - Barra de progreso de subida con feedback visual.

2. **Carpetas por Invitado**:
   - Cada subida genera una **carpeta/álbum digital** con el nombre o familia de quien lo subió.
   - Portada estilo collage con las mejores fotos del invitado y badge de cantidad de fotos.
   - Dedicatoria o mensaje en tarjeta de cita destacada.
   - Tocar la carpeta abre el modal completo con toda la galería y opción de descargar la dedicatoria.

3. **Muro de Recuerdos**:
   - Vista alternativa en cuadrícula con todas las fotos de todos los invitados en orden cronológico.

4. **Visor de Fotos en Pantalla Completa (Lightbox)**:
   - Zoom interactivo, desplazamiento táctil y con flechas del teclado (←, →, ESC).
   - Botón de descarga de cada fotografía en alta resolución.
   - Muestra el nombre de quién la tomó y su mensaje.

5. **Modo Proyector / Pantalla de Salón (Live Slideshow)**:
   - Diseñado para proyectarse en las pantallas gigantes o proyector del salón de fiesta.
   - Rotación automática cada 6 segundos con transiciones suaves.
   - Franja inferior elegante con la corona, el nombre del invitado y su dedicatoria en vivo.

6. **Código QR para Mesas**:
   - Genera el código QR del evento con la corona de Danna listo para proyectar o imprimir con 1 clic en tarjetas de mesa para los invitados.

7. **Almacenamiento en Google Fotos / Google Drive**:
   - Conector con **Google Apps Script Web App** (100% gratuito, sin límites de costo, aprovechando los 15GB libres de la cuenta de Google).
   - Crea automáticamente la carpeta principal `"15 Años Danna - Fotos de Invitados"` y una subcarpeta por cada invitado `"Nombre (Fecha)"`.
   - Incluye archivo de texto `Dedicatoria_[Invitado].txt` con el mensaje.
   - Modo local/demo integrado con datos de muestra precargados para usar de inmediato sin configuración previa.

---

## 🎨 Paleta de Diseño Quinceañera
- **Rose Gold**: `#C75D76` / `#D47A8E`
- **Champagne Gold**: `#D4AF37` / `#E5C378`
- **Soft Blush**: `#FFF0F3`
- **Deep Burgundy/Charcoal**: `#28141E`
- **Tipografía**: *Playfair Display* (títulos ceremoniales) & *Poppins* (interfaz moderna y legible).

---

## 🚀 Cómo Ejecutar la Aplicación Web

### Requisitos
- Flutter SDK 3.19+ (Probado en Flutter 3.47 con Dart 3.13)
- Google Chrome o cualquier navegador web moderno.

### En Desarrollo
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Google Chrome
flutter run -d chrome
```

### Compilar para Producción (Deploy Web)
```bash
flutter build web --release
```
Los archivos optimizados y listos para subir a cualquier hosting gratuito (Firebase Hosting, GitHub Pages, Netlify, Vercel) quedarán en la carpeta `build/web/`.

---

## ☁️ Configuración de Google Fotos & Google Drive (2 minutos)

La aplicación incluye un script listo para desplegar en tu cuenta de Google en la carpeta [`google_apps_script/Code.js`](./google_apps_script/Code.js).

### Pasos:
1. Abre [script.google.com](https://script.google.com/) con la cuenta de Google donde desees guardar las fotos.
2. Haz clic en **"Nuevo proyecto"** y nómbralo `Dots Memories Danna`.
3. Pega todo el contenido de [`google_apps_script/Code.js`](./google_apps_script/Code.js).
4. Haz clic en el botón azul superior **"Implementar" > "Nueva implementación"**.
5. En el engranaje ⚙️ selecciona **"Aplicación web"**.
6. Ajusta:
   - **Ejecutar como**: `Yo (tu correo)`
   - **Quién tiene acceso**: `Cualquiera` *(imprescindible para que los invitados suban fotos sin pedirles iniciar sesión)*.
7. Haz clic en **"Implementar"** y autoriza los permisos de Google Drive.
8. Copia la URL generada (termina en `/exec`).
9. En la aplicación web de Danna, abre el botón **"Google Nube" (engranaje ⚙️)**, activa el interruptor, pega la URL y haz clic en **"Probar Conexión"**.

A partir de ese momento, cada vez que un invitado suba fotos, se guardarán organizadas en tu Google Drive y podrás crear un álbum en Google Fotos con un solo clic.

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada, pantalla principal y navegación
├── models/
│   ├── app_config.dart                # Configuración de URLs y evento
│   ├── memory_folder.dart             # Modelo de carpeta por invitado y dedicatoria
│   └── memory_item.dart               # Modelo de fotografía y proveedores de imagen
├── services/
│   ├── download_helper.dart           # Descarga de fotos y utilidades web
│   ├── sample_data.dart               # Recuerdos de demostración iniciales
│   ├── storage_service.dart           # Servicio de almacenamiento local y Google Drive
│   └── web_helpers/                   # Abstracción condicional segura para web y tests
├── theme/
│   └── app_theme.dart                 # Paleta Rose Gold, fuentes y estilos
└── widgets/
    ├── event_header.dart              # Banner principal, métricas y acciones
    ├── folder_card.dart               # Tarjeta interactiva de carpeta de invitado
    ├── folder_detail_dialog.dart      # Vista detallada de carpeta y dedicatoria
    ├── live_slideshow_dialog.dart     # Modo pantalla gigante / proyector en vivo
    ├── photo_lightbox.dart            # Visor inmersivo a pantalla completa con zoom
    ├── qr_code_dialog.dart            # Generador e impresión de QR para mesas
    ├── settings_dialog.dart           # Ajustes de Google Nube y tutorial integrado
    └── upload_modal.dart              # Formulario de subida masiva de fotos y mensaje
```
