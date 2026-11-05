# 📸 Álbum Destino de Google Fotos para "15 Años de Danna"

**Enlace del Álbum de Google Fotos:**  
👉 [https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm](https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm)  
**ID del Álbum:** `AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm`

---

## 🌟 ¿Cómo funciona la integración?

1. **Subida Directa**: Los invitados suben sus fotos desde la app web Flutter (sin tener que iniciar sesión en Google).
2. **Recepción en Google Apps Script**:
   - Guarda las fotos en el Álbum de Google Fotos: `AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm`.
   - Crea una subcarpeta en Google Drive con el nombre del invitado y su archivo `Dedicatoria_[Invitado].txt`.
3. **Visualización Inmediata**:
   - En la aplicación web de Danna con los colores Verde Salvia y Rosado.
   - En el álbum oficial de Google Fotos accesible con el botón directo de la aplicación.

---

## 🚀 Despliegue en 2 minutos

1. Abre tu navegador e ingresa a [script.google.com](https://script.google.com/) con la cuenta de Google dueña del álbum de fotos.
2. Haz clic en **"Nuevo proyecto"** y nómbralo `Dots Memories Danna`.
3. Pega todo el contenido de [`Code.js`](./Code.js).
4. *(Opcional)* En el menú lateral izquierdo, haz clic en **Configuración del proyecto (⚙️)** y marca la casilla *"Mostrar archivo de manifiesto 'appsscript.json' en el editor"*. Luego pega el contenido de [`appsscript.json`](./appsscript.json).
5. Haz clic en **"Implementar" > "Nueva implementación"**.
6. En tipo de implementación (engranaje ⚙️) elige **"Aplicación web"**:
   - **Ejecutar como**: `Yo (tu correo de Google)`
   - **Quién tiene acceso**: **`Cualquiera`** *(permite que tus invitados suban fotos sin pedirles contraseña)*.
7. Haz clic en **"Implementar"** y autoriza los permisos.
8. Copia la **URL de la aplicación web** (terminada en `/exec`) y pégala en la app web de Danna en el botón de **Google Nube ☁️**.
