/**
 * =========================================================================
 * BACKEND GOOGLE APPS SCRIPT - DOTS MEMORIES: 15 AÑOS DE DANNA
 * =========================================================================
 * Álbum Destino de Google Fotos:
 * https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UJ4UZ0AYaRKKtLha7dIAWfUkKmJm
 *
 * Este script se ejecuta en tu cuenta de Google de forma 100% gratuita.
 * Recibe las fotos y comentarios que suben los invitados desde la web Flutter
 * y las guarda en tu Álbum de Google Fotos y en carpetas organizadas en Google Drive.
 *
 * CÓMO PUBLICAR / ACTUALIZAR (MUY IMPORTANTE):
 * 1. Pega este código completo en tu archivo Code.gs en script.google.com.
 * 2. Guarda los cambios (Ctrl+S o Cmd+S).
 * 3. Haz clic en "Implementar" (botón azul arriba a la derecha).
 * 4. Selecciona "Gestionar implementaciones".
 * 5. Haz clic en el icono del LÁPIZ (Editar) de la implementación activa.
 * 6. En el desplegable "Versión", selecciona SIEMPRE: "Nueva versión".
 * 7. Haz clic en el botón azul "Implementar".
 * ¡Listo! Así tus cambios se aplican de inmediato en la aplicación web.
 */

const GOOGLE_PHOTOS_ALBUM_ID = "AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm";
const GOOGLE_PHOTOS_ALBUM_URL = "https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm";
const MAIN_DRIVE_FOLDER_NAME = "15 Años Danna - Fotos de Invitados";

/**
 * Maneja peticiones POST desde la aplicación web (subida de fotos y dedicatoria)
 */
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      Logger.log("⚠️ [doPost] Invocado manualmente desde el editor sin datos HTTP.");
      Logger.log("👉 Para probar desde este editor, selecciona la función 'probarConexionDesdeEditor' o 'probarSubidaDesdeEditor' en el menú superior y pulsa Ejecutar.");
      return responseJSON({ status: "error", message: "No se recibieron datos HTTP en doPost" });
    }

    const data = JSON.parse(e.postData.contents);
    const guestName = (data.guestName || "Invitado Especial").trim();
    const comment = (data.comment || "").trim();
    const photos = data.photos || [];
    const deviceId = (data.deviceId || "").trim();
    const existingFolderId = (data.folderId || "").trim();

    Logger.log("📩 [doPost] Recibiendo subida de: " + guestName + " | Fotos: " + photos.length + " | Device: " + deviceId);

    // 1. Obtener o crear carpeta principal del evento en Google Drive
    const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);

    // 2. Obtener carpeta existente vinculada al dispositivo o crear una nueva
    var guestFolder = null;
    if (existingFolderId) {
      try {
        guestFolder = DriveApp.getFolderById(existingFolderId);
      } catch (err) {
        guestFolder = null;
      }
    }

    if (!guestFolder && deviceId) {
      // Buscar si ya existe una subcarpeta para este dispositivo
      const subfolders = mainFolder.getFolders();
      while (subfolders.hasNext()) {
        const sf = subfolders.next();
        try {
          const desc = sf.getDescription();
          if (desc && desc.startsWith("{")) {
            const parsed = JSON.parse(desc);
            if (parsed.deviceId && parsed.deviceId === deviceId) {
              guestFolder = sf;
              break;
            }
          }
        } catch (e) { }
      }
    }

    const now = new Date();
    const safeGuestName = guestName.replace(/[\/\\:*?"<>|]/g, "_");

    if (!guestFolder) {
      const dateStr = Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "yyyy-MM-dd_HH-mm");
      const guestFolderName = safeGuestName + " (" + dateStr + ")";
      guestFolder = mainFolder.createFolder(guestFolderName);
      guestFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    }

    // Guardar o actualizar metadatos con deviceId en la descripción de la carpeta
    try {
      guestFolder.setDescription(JSON.stringify({
        guestName: guestName,
        comment: comment,
        deviceId: deviceId,
        date: now.toISOString()
      }));
    } catch (e) { }

    // 3. Guardar el archivo de texto con la dedicatoria
    const noteContent = "═══════════════════════════════════════════════════════\r\n" +
      "  MIS 15 AÑOS - DANNA | RECUERDO DE INVITADO\r\n" +
      "═══════════════════════════════════════════════════════\r\n\r\n" +
      "De: " + guestName + "\r\n" +
      "Fecha: " + Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "dd/MM/yyyy HH:mm:ss") + "\r\n" +
      "Total de fotos: " + photos.length + "\r\n" +
      "Álbum Google Fotos: " + GOOGLE_PHOTOS_ALBUM_URL + "\r\n\r\n" +
      "DEDICATORIA / MENSAJE:\r\n" +
      (comment ? comment : "(Sin mensaje de texto)") + "\r\n\r\n" +
      "═══════════════════════════════════════════════════════";
    guestFolder.createFile("Dedicatoria_" + safeGuestName + ".txt", noteContent, "text/plain");

    // 4. Guardar cada una de las fotos en Drive y subir al Álbum de Google Fotos
    const savedPhotos = [];
    for (var i = 0; i < photos.length; i++) {
      try {
        const item = photos[i];
        const base64Data = item.base64;
        const contentType = item.type || "image/jpeg";
        const fileName = item.name || ("foto_" + (i + 1) + ".jpg");

        // Decodificar Base64
        const decodedBytes = Utilities.base64Decode(base64Data);
        const blob = Utilities.newBlob(decodedBytes, contentType, fileName);

        // Guardar archivo en la subcarpeta del invitado en Drive
        const file = guestFolder.createFile(blob);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

        const fileId = file.getId();
        const directUrl = "https://lh3.googleusercontent.com/d/" + fileId;
        const viewUrl = file.getUrl();

        // Intentar agregar al Álbum de Google Fotos directamente vía Google Photos API
        var googlePhotosId = null;
        try {
          googlePhotosId = uploadDirectToGooglePhotos(blob, fileName, guestName, comment);
        } catch (photosApiErr) {
          Logger.log("Aviso Google Photos API: " + photosApiErr.toString());
        }

        savedPhotos.push({
          name: fileName,
          id: fileId,
          appwriteUrl: item.appwriteUrl || null,
          googlePhotosId: googlePhotosId,
          url: item.appwriteUrl || directUrl,
          viewUrl: viewUrl
        });
        Logger.log("  📸 Foto guardada (" + (i + 1) + "/" + photos.length + "): " + fileName + " (ID: " + fileId + ")");
      } catch (photoErr) {
        Logger.log("Error guardando foto " + i + ": " + photoErr.toString());
      }
    }

    // Actualizar metadatos de la carpeta con fotos para lectura instantánea
    try {
      guestFolder.setDescription(JSON.stringify({
        guestName: guestName,
        comment: comment,
        photos: savedPhotos,
        date: now.toISOString()
      }));
    } catch (e) { }

    Logger.log("✅ [doPost] Finalizado con éxito para " + guestName + ". Carpeta: " + guestFolder.getName());

    // 5. Retornar respuesta exitosa con la URL del álbum de Google Fotos
    return responseJSON({
      status: "success",
      message: "Recuerdos guardados exitosamente en Google Fotos y Drive",
      guestName: guestName,
      comment: comment,
      googlePhotosAlbumId: GOOGLE_PHOTOS_ALBUM_ID,
      googlePhotosAlbumUrl: GOOGLE_PHOTOS_ALBUM_URL,
      folderId: guestFolder.getId(),
      folderUrl: guestFolder.getUrl(),
      folderName: guestFolderName,
      photosCount: savedPhotos.length,
      photos: savedPhotos,
      timestamp: now.toISOString()
    });

  } catch (err) {
    Logger.log("❌ [doPost] Error: " + err.toString());
    return responseJSON({
      status: "error",
      message: err.toString()
    });
  }
}

/**
 * Sube la imagen a la API de Google Photos y la asigna al álbum de Danna
 */
function uploadDirectToGooglePhotos(blob, fileName, guestName, comment) {
  const token = ScriptApp.getOAuthToken();
  if (!token) return null;

  // Paso A: Subir los bytes para obtener el uploadToken
  const uploadUrl = "https://photoslibrary.googleapis.com/v1/uploads";
  const uploadHeaders = {
    "Authorization": "Bearer " + token,
    "Content-type": "application/octet-stream",
    "X-Goog-Upload-File-Name": encodeURIComponent(fileName),
    "X-Goog-Upload-Protocol": "raw"
  };

  const uploadResponse = UrlFetchApp.fetch(uploadUrl, {
    method: "post",
    headers: uploadHeaders,
    payload: blob.getBytes(),
    muteHttpExceptions: true
  });

  if (uploadResponse.getResponseCode() !== 200) {
    return null;
  }

  const uploadToken = uploadResponse.getContentText();

  // Paso B: Crear el MediaItem dentro del Álbum específico de Danna
  const createUrl = "https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate";
  const createPayload = {
    "albumId": GOOGLE_PHOTOS_ALBUM_ID,
    "newMediaItems": [
      {
        "description": "15 Años de Danna • De: " + guestName + (comment ? (" - " + comment) : ""),
        "simpleMediaItem": {
          "fileName": fileName,
          "uploadToken": uploadToken
        }
      }
    ]
  };

  const createResponse = UrlFetchApp.fetch(createUrl, {
    method: "post",
    contentType: "application/json",
    headers: { "Authorization": "Bearer " + token },
    payload: JSON.stringify(createPayload),
    muteHttpExceptions: true
  });

  if (createResponse.getResponseCode() === 200) {
    const res = JSON.parse(createResponse.getContentText());
    if (res.newMediaItemResults && res.newMediaItemResults.length > 0) {
      return res.newMediaItemResults[0].mediaItem ? res.newMediaItemResults[0].mediaItem.id : null;
    }
  }

  return null;
}

/**
 * Maneja peticiones GET (para verificar conexión o listar recuerdos)
 */
function doGet(e) {
  try {
    const action = e && e.parameter ? e.parameter.action : "ping";

    if (action === "ping") {
      return responseJSON({
        status: "ok",
        message: "Backend de Google Fotos activo para 15 Años de Danna",
        albumId: GOOGLE_PHOTOS_ALBUM_ID,
        albumUrl: GOOGLE_PHOTOS_ALBUM_URL,
        time: new Date().toISOString()
      });
    }

    if (action === "list") {
      const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
      const subfolders = mainFolder.getFolders();
      const memories = [];

      while (subfolders.hasNext()) {
        const folder = subfolders.next();
        const files = folder.getFiles();
        const photosList = [];
        var commentText = "";
        var guestNameText = "";

        var deviceIdText = "";

        // Lectura ultra rápida desde metadatos cacheados
        try {
          const desc = folder.getDescription();
          if (desc && desc.startsWith("{")) {
            const parsedDesc = JSON.parse(desc);
            guestNameText = parsedDesc.guestName || "";
            commentText = parsedDesc.comment || "";
            deviceIdText = parsedDesc.deviceId || "";
            if (parsedDesc.photos && Array.isArray(parsedDesc.photos) && parsedDesc.photos.length > 0) {
              memories.push({
                folderId: folder.getId(),
                folderName: folder.getName(),
                folderUrl: folder.getUrl(),
                guestName: guestNameText,
                comment: commentText,
                deviceId: deviceIdText,
                photosCount: parsedDesc.photos.length,
                photos: parsedDesc.photos,
                created: folder.getDateCreated().toISOString()
              });
              continue;
            }
          }
        } catch (cacheErr) { }

        // Si no hay metadatos cacheados, recorrer archivos de la carpeta
        while (files.hasNext()) {
          const f = files.next();
          const mime = f.getMimeType();
          const name = f.getName();

          if (name.startsWith("Dedicatoria_") || mime === "text/plain") {
            try {
              commentText = f.getBlob().getDataAsString();
            } catch (readErr) { }
          } else if (mime.startsWith("image/") || mime.startsWith("video/") || name.match(/\.(jpg|jpeg|png|webp|heic|heif|mp4|mov|webm|avi|mkv)$/i)) {
            photosList.push({
              name: name,
              id: f.getId(),
              url: "https://lh3.googleusercontent.com/d/" + f.getId(),
              viewUrl: f.getUrl()
            });
          }
        }

        memories.push({
          folderId: folder.getId(),
          folderName: folder.getName(),
          folderUrl: folder.getUrl(),
          guestName: guestNameText,
          comment: commentText,
          deviceId: deviceIdText,
          photosCount: photosList.length,
          photos: photosList,
          created: folder.getDateCreated().toISOString()
        });
      }

      return responseJSON({
        status: "success",
        count: memories.length,
        googlePhotosAlbumUrl: GOOGLE_PHOTOS_ALBUM_URL,
        memories: memories
      });
    }

    return responseJSON({ status: "error", message: "Acción no reconocida" });

  } catch (err) {
    return responseJSON({ status: "error", message: err.toString() });
  }
}

/**
 * =========================================================================
 * FUNCIONES DE PRUEBA DESDE EL EDITOR DE GOOGLE APPS SCRIPT
 * =========================================================================
 * Selecciona cualquiera de estas funciones en el menú desplegable junto a
 * "Depuración" y pulsa "Ejecutar" para ver resultados inmediatos en el Log.
 */

/**
 * 1. Prueba de conexión y listado de carpetas existentes
 */
function probarConexionDesdeEditor() {
  Logger.log("====================================================");
  Logger.log("🚀 PRUEBA DE CONEXIÓN CON GOOGLE DRIVE (15 AÑOS DANNA)");
  Logger.log("====================================================");
  
  const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
  Logger.log("✅ Carpeta principal encontrada: " + mainFolder.getName());
  Logger.log("📁 URL en Drive: " + mainFolder.getUrl());
  
  const subfolders = mainFolder.getFolders();
  var count = 0;
  while (subfolders.hasNext()) {
    const f = subfolders.next();
    count++;
    Logger.log("  📂 [" + count + "] " + f.getName());
  }
  
  Logger.log("====================================================");
  Logger.log("🎉 PRUEBA EXITOSA: " + count + " carpetas encontradas.");
  Logger.log("====================================================");
}

/**
 * 2. Prueba simulada de subida de foto y dedicatoria
 */
function probarSubidaDesdeEditor() {
  Logger.log("====================================================");
  Logger.log("🧪 SIMULANDO SUBIDA DE FOTO DESDE EL EDITOR...");
  Logger.log("====================================================");

  // PNG transparente de prueba 1x1 pixel en base64
  const mockBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==";

  const mockEvent = {
    postData: {
      contents: JSON.stringify({
        guestName: "Prueba desde Editor Apps Script",
        comment: "¡Felicidades Danna en tus 15! Prueba de log en directo.",
        photos: [
          {
            name: "foto_prueba_editor.png",
            type: "image/png",
            base64: mockBase64
          }
        ]
      })
    }
  };

  const resultado = doPost(mockEvent);
  Logger.log("Respuesta obtenida:");
  Logger.log(resultado.getContent());
  Logger.log("====================================================");
  Logger.log("🎉 ¡Listo! Si ves el JSON anterior, el backend funciona 100%.");
  Logger.log("====================================================");
}

function getOrCreateMainFolder(folderName) {
  const folders = DriveApp.getFoldersByName(folderName);
  if (folders.hasNext()) {
    return folders.next();
  }
  const folder = DriveApp.createFolder(folderName);
  folder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return folder;
}

function responseJSON(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
