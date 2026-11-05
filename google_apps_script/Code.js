/**
 * =========================================================================
 * BACKEND GOOGLE APPS SCRIPT - DOTS MEMORIES: 15 AÑOS DE DANNA
 * =========================================================================
 * Álbum Destino de Google Fotos:
 * https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm
 *
 * Este script se ejecuta en tu cuenta de Google de forma 100% gratuita.
 * Recibe las fotos y comentarios que suben los invitados desde la web Flutter
 * y las guarda en tu Álbum de Google Fotos y en carpetas organizadas en Google Drive.
 *
 * INSTRUCCIONES DE INSTALACIÓN (2 minutos):
 * 1. Entra a https://script.google.com/ y haz clic en "Nuevo proyecto".
 * 2. Borra todo el código que aparezca y pega este archivo completo.
 * 3. Haz clic en "Implementar" (botón azul arriba a la derecha) > "Nueva implementación".
 * 4. En tipo de implementación (icono de engranaje) selecciona "Aplicación web".
 * 5. Configura:
 *    - Descripción: "Dots Memories Danna - Álbum Google Fotos"
 *    - Ejecutar como: "Yo (tu correo de Google)"
 *    - Quién tiene acceso: "Cualquiera" (Anyone) -> Permite que los invitados suban fotos sin login.
 * 6. Haz clic en "Implementar", autoriza los permisos de Google Drive y Fotos.
 * 7. Copia la "URL de la aplicación web" (termina en /exec) y pégala en la app web de Danna
 *    en el botón de Ajustes ⚙️ (Google Nube).
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
      return responseJSON({ status: "error", message: "No se recibieron datos" });
    }

    const data = JSON.parse(e.postData.contents);
    const guestName = (data.guestName || "Invitado Especial").trim();
    const comment = (data.comment || "").trim();
    const photos = data.photos || [];

    // 1. Obtener o crear carpeta principal del evento en Google Drive
    const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);

    // 2. Crear subcarpeta para el invitado con fecha y hora
    const now = new Date();
    const dateStr = Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "yyyy-MM-dd_HH-mm");
    const safeGuestName = guestName.replace(/[\/\\:*?"<>|]/g, "_");
    const guestFolderName = safeGuestName + " (" + dateStr + ")";
    const guestFolder = mainFolder.createFolder(guestFolderName);

    // Dar permisos de lectura
    guestFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    // Guardar metadatos en la descripción de la carpeta para lectura ultra rápida
    try {
      guestFolder.setDescription(JSON.stringify({
        guestName: guestName,
        comment: comment,
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
          googlePhotosId: googlePhotosId,
          url: directUrl,
          viewUrl: viewUrl
        });
      } catch (photoErr) {
        Logger.log("Error guardando foto " + i + ": " + photoErr.toString());
      }
    }

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
    Logger.log("Error en doPost: " + err.toString());
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

        // Lectura ultra rápida desde descripción
        try {
          const desc = folder.getDescription();
          if (desc) {
            const meta = JSON.parse(desc);
            guestNameText = meta.guestName || "";
            commentText = meta.comment || "";
          }
        } catch (e) { }

        while (files.hasNext()) {
          const file = files.next();
          const mime = file.getMimeType();
          if (mime.indexOf("image") !== -1) {
            photosList.push({
              name: file.getName(),
              id: file.getId(),
              url: "https://lh3.googleusercontent.com/d/" + file.getId(),
              viewUrl: file.getUrl()
            });
          } else if (!commentText && file.getName().indexOf("Dedicatoria") !== -1) {
            try {
              commentText = file.getBlob().getDataAsString();
            } catch (e) { }
          }
        }

        memories.push({
          folderId: folder.getId(),
          folderName: folder.getName(),
          guestName: guestNameText,
          folderUrl: folder.getUrl(),
          comment: commentText,
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
