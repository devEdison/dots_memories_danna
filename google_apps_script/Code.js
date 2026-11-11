/**
 * =========================================================================
 * BACKEND GOOGLE APPS SCRIPT - DOTS MEMORIES: 15 AÑOS DE DANNA
 * =========================================================================
 * Álbum Destino de Google Fotos:
 * https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm
 *
 * Almacenamiento exclusivo en Google (Drive + Google Fotos), optimizado
 * con LockService por sección corta, creación por lotes en Google Photos API
 * y caché compacta de metadatos para evitar saturar las subidas.
 *
 * CÓMO PUBLICAR / ACTUALIZAR (MUY IMPORTANTE):
 * 1. Pega este código completo en tu archivo Code.gs en script.google.com.
 * 2. Guarda los cambios (Ctrl+S o Cmd+S).
 * 3. Haz clic en "Implementar" -> "Gestionar implementaciones".
 * 4. Haz clic en el icono del LÁPIZ (Editar) de la implementación activa.
 * 5. En "Versión", selecciona SIEMPRE: "Nueva versión" y pulsa "Implementar".
 */

const GOOGLE_PHOTOS_ALBUM_ID = "AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm";
const GOOGLE_PHOTOS_ALBUM_URL = "https://photos.google.com/album/AF1QipOhge4RLXPuUJ4UZ0AYaRKKtLha7dIAWfUkKmJm";
const MAIN_DRIVE_FOLDER_NAME = "15 Años Danna - Fotos de Invitados";

function acquireScriptLock_(waitMs) {
  try {
    const lock = LockService.getScriptLock();
    if (lock.tryLock(waitMs || 10000)) {
      return lock;
    }
  } catch (e) { }
  return null;
}

function buildPhotoPayload_(id, name, viewUrl) {
  return {
    name: name,
    id: id,
    url: "https://lh3.googleusercontent.com/d/" + id,
    viewUrl: viewUrl || ("https://drive.google.com/file/d/" + id + "/view")
  };
}

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
    if (data.action === "deleteFolder") {
      return deleteFolderInDrive_(data);
    }
    if (data.action === "deleteFile") {
      return deleteFileInDrive_(data);
    }

    const guestName = (data.guestName || "Invitado Especial").trim();
    const comment = (data.comment || "").trim();
    const photos = data.photos || [];
    const deviceId = (data.deviceId || "").trim();
    const existingFolderId = (data.folderId || "").trim();
    const skipDedication = data.skipDedication === true;

    Logger.log("📩 [doPost] Recibiendo subida de: " + guestName + " | Archivos: " + photos.length + " | Device: " + deviceId);

    const safeGuestName = guestName.replace(/[\/\\:*?"<>|]/g, "_");
    const now = new Date();

    // 1. Sección corta con bloqueo únicamente para buscar/crear carpetas sin duplicados
    var mainFolder = null;
    var guestFolder = null;
    const folderLock = acquireScriptLock_(12000);
    try {
      mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);

      // A) Buscar por ID directo si fue enviado por la app
      if (existingFolderId) {
        try {
          guestFolder = DriveApp.getFolderById(existingFolderId);
        } catch (err) {
          guestFolder = null;
        }
      }

      // B) Buscar por deviceId en los metadatos de las carpetas existentes
      if (!guestFolder && deviceId) {
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
          } catch (e2) { }
        }
      }

      // C) Fallback: Buscar por nombre del invitado
      if (!guestFolder && safeGuestName) {
        const subfolders = mainFolder.getFolders();
        while (subfolders.hasNext()) {
          const sf = subfolders.next();
          const sfName = sf.getName();
          if (sfName.startsWith(safeGuestName + " (") || sfName.toLowerCase() === safeGuestName.toLowerCase()) {
            guestFolder = sf;
            break;
          }
        }
      }

      if (!guestFolder) {
        const dateStr = Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "yyyy-MM-dd_HH-mm");
        const guestFolderName = safeGuestName + " (" + dateStr + ")";
        guestFolder = mainFolder.createFolder(guestFolderName);
        guestFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        try {
          guestFolder.setDescription(JSON.stringify({
            guestName: guestName,
            comment: comment,
            deviceId: deviceId,
            photos: [],
            date: now.toISOString()
          }));
        } catch (descErr) { }
      }
    } finally {
      if (folderLock) {
        try { folderLock.releaseLock(); } catch (relErr) { }
      }
    }

    // 2. Guardar o actualizar la dedicatoria solo cuando corresponde (evita reescrituras por lote)
    if (!skipDedication) {
      const noteContent = "═══════════════════════════════════════════════════════\r\n" +
        "  MIS 15 AÑOS - DANNA | RECUERDO DE INVITADO\r\n" +
        "═══════════════════════════════════════════════════════\r\n\r\n" +
        "De: " + guestName + "\r\n" +
        "Fecha: " + Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "dd/MM/yyyy HH:mm:ss") + "\r\n" +
        "Álbum Google Fotos: " + GOOGLE_PHOTOS_ALBUM_URL + "\r\n\r\n" +
        "DEDICATORIA / MENSAJE:\r\n" +
        (comment ? comment : "(Sin mensaje de texto)") + "\r\n\r\n" +
        "═══════════════════════════════════════════════════════";
      const dedicationFileName = "Dedicatoria_" + safeGuestName + ".txt";
      const existingDedication = guestFolder.getFilesByName(dedicationFileName);
      if (existingDedication.hasNext()) {
        existingDedication.next().setContent(noteContent);
      } else {
        guestFolder.createFile(dedicationFileName, noteContent, "text/plain");
      }
    }

    // 3. Guardar cada archivo en Drive y preparar tokens para batchCreate en Google Fotos
    const savedPhotos = [];
    const savedCompact = [];
    const pendingPhotosApiItems = [];
    var googlePhotosToken = null;
    try {
      googlePhotosToken = ScriptApp.getOAuthToken();
    } catch (tokErr) { }
    var photosApiAvailable = Boolean(googlePhotosToken);

    for (var i = 0; i < photos.length; i++) {
      try {
        const item = photos[i];
        const base64Data = item.base64;
        const contentType = item.type || "image/jpeg";
        const fileName = item.name || ("archivo_" + (i + 1) + ".jpg");

        const decodedBytes = Utilities.base64Decode(base64Data);
        const blob = Utilities.newBlob(decodedBytes, contentType, fileName);

        const file = guestFolder.createFile(blob);
        try {
          file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
        } catch (shareErr) { }

        const fileId = file.getId();
        const viewUrl = file.getUrl();

        if (photosApiAvailable) {
          const uploadToken = uploadBytesToGooglePhotos_(googlePhotosToken, decodedBytes, fileName);
          if (uploadToken === "__FORBIDDEN__") {
            photosApiAvailable = false;
          } else if (uploadToken) {
            pendingPhotosApiItems.push({ fileName: fileName, uploadToken: uploadToken });
          }
        }

        savedPhotos.push(buildPhotoPayload_(fileId, fileName, viewUrl));
        savedCompact.push({ name: fileName, id: fileId });
        Logger.log("  📸 Archivo guardado (" + (i + 1) + "/" + photos.length + "): " + fileName + " (ID: " + fileId + ")");
      } catch (photoErr) {
        Logger.log("Error guardando archivo " + i + ": " + photoErr.toString());
      }
    }

    // Registrar todo el lote en el álbum de Google Fotos en 1 sola llamada batchCreate
    if (photosApiAvailable && pendingPhotosApiItems.length > 0) {
      try {
        batchCreateGooglePhotosMediaItems_(googlePhotosToken, pendingPhotosApiItems, guestName, comment);
      } catch (batchErr) {
        Logger.log("Aviso batchCreate Google Fotos: " + batchErr.toString());
      }
    }

    // 4. Sección corta con bloqueo para fusionar metadatos cacheados de la carpeta sin colisiones
    var finalComment = comment;
    var totalCount = savedCompact.length;
    const metaLock = acquireScriptLock_(10000);
    try {
      var mergedCompact = savedCompact;
      try {
        const oldDesc = guestFolder.getDescription();
        if (oldDesc && oldDesc.startsWith("{")) {
          const oldParsed = JSON.parse(oldDesc);
          if (oldParsed.photos && Array.isArray(oldParsed.photos) && oldParsed.photos.length > 0) {
            const newNames = {};
            for (var k = 0; k < savedCompact.length; k++) {
              newNames[savedCompact[k].name] = true;
            }
            const prior = [];
            for (var pIdx = 0; pIdx < oldParsed.photos.length; pIdx++) {
              const oldItem = oldParsed.photos[pIdx];
              const oldName = oldItem.name || oldItem.n || "";
              const oldId = oldItem.id || "";
              if (oldId && !newNames[oldName]) {
                prior.push({ name: oldName, id: oldId });
              }
            }
            mergedCompact = prior.concat(savedCompact);
          }
          if (!finalComment && oldParsed.comment) {
            finalComment = oldParsed.comment;
          }
        }
      } catch (readDescErr) { }

      totalCount = mergedCompact.length;
      const metaObj = {
        guestName: guestName,
        comment: finalComment,
        deviceId: deviceId,
        photos: mergedCompact,
        date: now.toISOString()
      };
      var metaJson = JSON.stringify(metaObj);
      // Si la carpeta creciera tanto que supera ~28 KB, dejar que doGet lea los archivos directo
      if (metaJson.length > 28000) {
        metaObj.photos = [];
        metaJson = JSON.stringify(metaObj);
      }
      guestFolder.setDescription(metaJson);
    } catch (e3) {
      Logger.log("Aviso actualizando descripción: " + e3.toString());
    } finally {
      if (metaLock) {
        try { metaLock.releaseLock(); } catch (relErr2) { }
      }
    }

    Logger.log("✅ [doPost] Finalizado con éxito para " + guestName + ". Carpeta: " + guestFolder.getName() + " (Total archivos: " + totalCount + ")");

    return responseJSON({
      status: "success",
      message: "Recuerdos guardados exitosamente en Google Drive y Google Fotos",
      guestName: guestName,
      comment: finalComment,
      googlePhotosAlbumId: GOOGLE_PHOTOS_ALBUM_ID,
      googlePhotosAlbumUrl: GOOGLE_PHOTOS_ALBUM_URL,
      folderId: guestFolder.getId(),
      folderUrl: guestFolder.getUrl(),
      folderName: guestFolder.getName(),
      photosCount: totalCount,
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

function uploadBytesToGooglePhotos_(token, rawBytes, fileName) {
  try {
    const uploadResponse = UrlFetchApp.fetch("https://photoslibrary.googleapis.com/v1/uploads", {
      method: "post",
      headers: {
        "Authorization": "Bearer " + token,
        "Content-type": "application/octet-stream",
        "X-Goog-Upload-File-Name": encodeURIComponent(fileName),
        "X-Goog-Upload-Protocol": "raw"
      },
      payload: rawBytes,
      muteHttpExceptions: true
    });
    const code = uploadResponse.getResponseCode();
    if (code === 401 || code === 403) {
      return "__FORBIDDEN__";
    }
    if (code === 200) {
      return uploadResponse.getContentText();
    }
  } catch (e) { }
  return null;
}

function batchCreateGooglePhotosMediaItems_(token, items, guestName, comment) {
  const newMediaItems = [];
  for (var i = 0; i < items.length; i++) {
    newMediaItems.push({
      "description": "15 Años de Danna • De: " + guestName + (comment ? (" - " + comment) : ""),
      "simpleMediaItem": {
        "fileName": items[i].fileName,
        "uploadToken": items[i].uploadToken
      }
    });
  }

  UrlFetchApp.fetch("https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate", {
    method: "post",
    contentType: "application/json",
    headers: { "Authorization": "Bearer " + token },
    payload: JSON.stringify({
      "albumId": GOOGLE_PHOTOS_ALBUM_ID,
      "newMediaItems": newMediaItems
    }),
    muteHttpExceptions: true
  });
}

/**
 * Busca una subcarpeta dentro de la carpeta principal por folderId o deviceId cacheado
 */
function findSubfolderInMain_(mainFolder, folderId, deviceId) {
  const subfolders = mainFolder.getFolders();
  while (subfolders.hasNext()) {
    const sf = subfolders.next();
    if (folderId && sf.getId() === folderId) {
      return sf;
    }
    if (deviceId) {
      try {
        const desc = sf.getDescription();
        if (desc && desc.startsWith("{")) {
          const parsed = JSON.parse(desc);
          if (parsed.deviceId && parsed.deviceId === deviceId) {
            return sf;
          }
        }
      } catch (parseErr) { }
    }
  }
  return null;
}

/**
 * Elimina (envía a la papelera de Google Drive) una subcarpeta dentro de la carpeta del evento
 */
function deleteFolderInDrive_(data) {
  const folderId = (data.folderId || "").trim();
  const deviceId = (data.deviceId || "").trim();

  if (!folderId && !deviceId) {
    return responseJSON({
      status: "error",
      action: "deleteFolder",
      message: "Falta el identificador de la carpeta a eliminar."
    });
  }

  const lock = acquireScriptLock_(10000);
  try {
    const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
    const targetFolder = findSubfolderInMain_(mainFolder, folderId, deviceId);

    if (!targetFolder) {
      Logger.log("ℹ️ [deleteFolder] Carpeta no encontrada en Drive (posiblemente ya eliminada): " + folderId);
      return responseJSON({
        status: "success",
        action: "deleteFolder",
        deletedFolderId: folderId,
        trashed: false,
        alreadyMissing: true,
        message: "La carpeta ya no estaba en Google Drive."
      });
    }

    const deletedId = targetFolder.getId();
    const deletedName = targetFolder.getName();
    targetFolder.setTrashed(true);
    Logger.log("🗑️ [deleteFolder] Carpeta enviada a la papelera de Drive: " + deletedName + " (" + deletedId + ")");

    return responseJSON({
      status: "success",
      action: "deleteFolder",
      deletedFolderId: deletedId,
      deletedFolderName: deletedName,
      trashed: true,
      message: "Carpeta eliminada en Google Drive."
    });
  } catch (err) {
    Logger.log("❌ [deleteFolder] Error eliminando carpeta: " + err.toString());
    return responseJSON({
      status: "error",
      action: "deleteFolder",
      message: err.toString()
    });
  } finally {
    if (lock) {
      try { lock.releaseLock(); } catch (relErr) { }
    }
  }
}

/**
 * Elimina (envía a la papelera de Google Drive) un archivo individual y actualiza la caché de su carpeta
 */
function deleteFileInDrive_(data) {
  const fileId = (data.fileId || "").trim();
  const folderId = (data.folderId || "").trim();
  const deviceId = (data.deviceId || "").trim();
  const fileName = (data.fileName || "").trim();

  if (!fileId && !(fileName && (folderId || deviceId))) {
    return responseJSON({
      status: "error",
      action: "deleteFile",
      message: "Falta el identificador del archivo a eliminar."
    });
  }

  const lock = acquireScriptLock_(10000);
  try {
    const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
    const mainFolderId = mainFolder.getId();
    var targetFolder = findSubfolderInMain_(mainFolder, folderId, deviceId);
    var targetFile = null;

    if (fileId) {
      try {
        const candidate = DriveApp.getFileById(fileId);
        const parents = candidate.getParents();
        while (parents.hasNext()) {
          const parent = parents.next();
          if (targetFolder && parent.getId() === targetFolder.getId()) {
            targetFile = candidate;
            break;
          }
          const grandParents = parent.getParents();
          while (grandParents.hasNext()) {
            if (grandParents.next().getId() === mainFolderId) {
              targetFile = candidate;
              if (!targetFolder) {
                targetFolder = parent;
              }
              break;
            }
          }
          if (targetFile) break;
        }
      } catch (lookupErr) { }
    }

    if (!targetFile && targetFolder && fileName) {
      const filesByName = targetFolder.getFilesByName(fileName);
      if (filesByName.hasNext()) {
        targetFile = filesByName.next();
      }
    }

    const resolvedFileId = targetFile ? targetFile.getId() : fileId;
    const resolvedFileName = targetFile ? targetFile.getName() : fileName;

    if (targetFile && !targetFile.isTrashed()) {
      targetFile.setTrashed(true);
      Logger.log("🗑️ [deleteFile] Archivo enviado a papelera de Drive: " + resolvedFileName + " (" + resolvedFileId + ")");
    }

    // Actualizar metadatos cacheados de la carpeta padre para evitar que reaparezca en listados
    if (targetFolder) {
      try {
        const desc = targetFolder.getDescription();
        if (desc && desc.startsWith("{")) {
          const parsed = JSON.parse(desc);
          if (parsed.photos && Array.isArray(parsed.photos)) {
            parsed.photos = parsed.photos.filter(function (p) {
              if (!p) return false;
              if (resolvedFileId && p.id && p.id === resolvedFileId) return false;
              const pName = p.name || p.n || "";
              if (!resolvedFileId && fileName && pName === fileName) return false;
              return true;
            });
            targetFolder.setDescription(JSON.stringify(parsed));
          }
        }
      } catch (metaErr) {
        Logger.log("⚠️ [deleteFile] Aviso actualizando metadatos: " + metaErr.toString());
      }
    }

    return responseJSON({
      status: "success",
      action: "deleteFile",
      deletedFileId: resolvedFileId,
      deletedFileName: resolvedFileName,
      trashed: Boolean(targetFile),
      alreadyMissing: !targetFile,
      message: targetFile
        ? "Foto o video eliminado en Google Drive."
        : "El archivo ya no estaba en Google Drive."
    });
  } catch (err) {
    Logger.log("❌ [deleteFile] Error eliminando archivo: " + err.toString());
    return responseJSON({
      status: "error",
      action: "deleteFile",
      message: err.toString()
    });
  } finally {
    if (lock) {
      try { lock.releaseLock(); } catch (relErr) { }
    }
  }
}

/**
 * Maneja peticiones GET (para verificar conexión o listar recuerdos)
 */
function doGet(e) {
  try {
    const action = e && e.parameter ? e.parameter.action : "ping";

    if (action === "ping") {
      const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
      return responseJSON({
        status: "ok",
        message: "Backend de Google Fotos y Google Drive activo para 15 Años de Danna",
        albumId: GOOGLE_PHOTOS_ALBUM_ID,
        albumUrl: GOOGLE_PHOTOS_ALBUM_URL,
        mainDriveFolderUrl: mainFolder.getUrl(),
        mainDriveFolderName: MAIN_DRIVE_FOLDER_NAME,
        time: new Date().toISOString()
      });
    }

    if (action === "list") {
      const mainFolder = getOrCreateMainFolder(MAIN_DRIVE_FOLDER_NAME);
      const subfolders = mainFolder.getFolders();
      const memories = [];

      while (subfolders.hasNext()) {
        const folder = subfolders.next();
        const photosList = [];
        var commentText = "";
        var guestNameText = "";

        var deviceIdText = "";

        // Lectura ultra rápida desde metadatos cacheados (antes de listar archivos de Drive)
        try {
          const desc = folder.getDescription();
          if (desc && desc.startsWith("{")) {
            const parsedDesc = JSON.parse(desc);
            guestNameText = parsedDesc.guestName || "";
            commentText = parsedDesc.comment || "";
            deviceIdText = parsedDesc.deviceId || "";
            if (parsedDesc.photos && Array.isArray(parsedDesc.photos) && parsedDesc.photos.length > 0) {
              const normalizedPhotos = [];
              for (var nIdx = 0; nIdx < parsedDesc.photos.length; nIdx++) {
                const rawP = parsedDesc.photos[nIdx];
                if (rawP && rawP.id) {
                  normalizedPhotos.push(
                    buildPhotoPayload_(rawP.id, rawP.name || rawP.n || ("archivo_" + (nIdx + 1) + ".jpg"), rawP.viewUrl)
                  );
                }
              }
              if (normalizedPhotos.length > 0) {
                memories.push({
                  folderId: folder.getId(),
                  folderName: folder.getName(),
                  folderUrl: folder.getUrl(),
                  guestName: guestNameText,
                  comment: commentText,
                  deviceId: deviceIdText,
                  photosCount: normalizedPhotos.length,
                  photos: normalizedPhotos,
                  created: folder.getDateCreated().toISOString()
                });
                continue;
              }
            }
          }
        } catch (cacheErr) { }

        // Si no hay metadatos cacheados, recorrer archivos de la carpeta
        const files = folder.getFiles();
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
        mainDriveFolderUrl: mainFolder.getUrl(),
        mainDriveFolderName: MAIN_DRIVE_FOLDER_NAME,
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
