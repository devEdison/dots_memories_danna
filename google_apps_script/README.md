# 📸 Backend de Google Fotos / Google Drive para "15 Años de Danna"

Este script de Google Apps Script permite que los invitados a los 15 de Danna suban **todas las fotos que quieran** junto con sus dedicatorias desde la app web Flutter, guardándolas automáticamente en la cuenta de Google de la quinceañera o de sus padres, **sin costo de almacenamiento y sin pedir login a los invitados**.

---

## 🌟 ¿Cómo funciona con Google Fotos y Google Drive?

1. **Almacenamiento Gratuito de Google**: Cada cuenta de Google incluye **15 GB de almacenamiento gratuito**, lo que equivale a más de **5,000 fotos en alta calidad**. Si la familia ya tiene Google One, tienen 100GB o más.
2. **Organización en Carpetas**: Cada invitado crea su propia carpeta dentro de `"15 Años Danna - Fotos de Invitados"`, conteniendo:
   - Todas sus fotos originales sin límite.
   - Un archivo de texto `Dedicatoria_[Invitado].txt` con el mensaje y la fecha.
3. **Sincronización con Google Fotos**:
   - En Google Drive, puedes seleccionar la carpeta `"15 Años Danna - Fotos de Invitados"` y crear un álbum en Google Fotos con 1 solo clic ("Subir a Google Fotos" o "Crear álbum en Google Fotos").
   - Las fotos también se visualizan inmediatamente en la app web en tiempo real.

---

## 🚀 Pasos de Instalación (2 minutos)

1. Abre tu navegador e ingresa a [script.google.com](https://script.google.com/) con la cuenta de Google donde desees guardar las fotos.
2. Haz clic en el botón superior izquierdo **"Nuevo proyecto"**.
3. Ponle un nombre al proyecto, por ejemplo: `Dots Memories Danna Backend`.
4. Borra el código que aparece por defecto en el editor y pega todo el contenido de [`Code.js`](./Code.js).
5. Haz clic en el botón azul **"Implementar"** (arriba a la derecha) y selecciona **"Nueva implementación"**.
6. En el selector de tipo (icono de engranaje ⚙️ a la izquierda), elige **"Aplicación web"**.
7. Llena los datos:
   - **Descripción**: `Backend Danna XV`
   - **Ejecutar como**: `Yo (tu correo de Google)`
   - **Quién tiene acceso**: **`Cualquiera`** *(Importante: Debe ser "Cualquiera" para que los invitados puedan subir fotos sin tener que iniciar sesión ni pedir permisos)*.
8. Haz clic en **"Implementar"**.
9. Google te pedirá "Autorizar acceso":
   - Selecciona tu cuenta de Google.
   - Si sale una pantalla de "Google no ha verificado esta aplicación", haz clic en **"Configuración avanzada"** (o "Avanzado") y luego en **"Ir a Dots Memories Danna Backend (no seguro)"**.
   - Haz clic en **"Permitir"**.
10. Se mostrará una ventana con la **"URL de la aplicación web"** (que termina en `/exec`).
11. **Copia esa URL** y en la app web de Danna, abre el botón de **Configuración ⚙️** y pégala.

¡Listo! A partir de ese momento, cada foto subida se guardará directamente en tu Google Drive.

