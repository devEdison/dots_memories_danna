/**
 * =========================================================================
 * BACKEND GOOGLE APPS SCRIPT - DOTS MEMORIES: 15 AÑOS DE DANNA
 * =========================================================================
 * Este script se ejecuta en Google Cloud / Google Drive de forma 100% gratuita.
 * Recibe las fotos y comentarios que suben los invitados desde la web Flutter
 * y las guarda automáticamente en carpetas individuales organizadas por invitado.
 *
 * INSTRUCCIONES DE INSTALACIÓN (Tarda 2 minutos):
 * 1. Entra a https://script.google.com/ y haz clic en "Nuevo proyecto".
 * 2. Borra todo el código que aparezca y pega este archivo completo.
 * 3. Haz clic en "Implementar" (botón azul arriba a la derecha) > "Nueva implementación".
 * 4. En tipo de implementación (icono de engranaje) selecciona "Aplicación web".
 * 5. Configura:
 *    - Descripción: "Dots Memories Danna Backend"
 *    - Ejecutar como: "Yo (tu correo de Google)"
 *    - Quién tiene acceso: "Cualquiera" (Anyone) -> IMPORTANTE para que los invitados puedan subir sin iniciar sesión.
 * 6. Haz clic en "Implementar", autoriza los permisos de Google Drive.
 * 7. Copia la "URL de la aplicación web" (termina en /exec) y pégala en la app Flutter
 *    en el botón de Configuración (engranaje). ¡Listo!
 */

const MAIN_FOLDER_NAME = "15 Años Danna - Fotos de Invitados";

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

    // 1. Obtener o crear carpeta principal del evento
    const mainFolder = getOrCreateMainFolder(MAIN_FOLDER_NAME);

    // 2. Crear subcarpeta para el invitado con fecha y hora
    const now = new Date();
    const dateStr = Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "yyyy-MM-dd_HH-mm");
    const safeGuestName = guestName.replace(/[\/\\:*?"<>|]/g, "_");
    const guestFolderName = safeGuestName + " (" + dateStr + ")";
    const guestFolder = mainFolder.createFolder(guestFolderName);

    // Dar permisos de lectura con enlace
    guestFolder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

    // 3. Guardar el archivo de texto con la dedicatoria
    const noteContent = "═══════════════════════════════════════════════════════\r\n" +
                        "  MIS 15 AÑOS - DANNA | RECUERDO DE INVITADO\r\n" +
                        "═══════════════════════════════════════════════════════\r\n\r\n" +
                        "De: " + guestName + "\r\n" +
                        "Fecha: " + Utilities.formatDate(now, Session.getScriptTimeZone() || "GMT-6", "dd/MM/yyyy HH:mm:ss") + "\r\n" +
                        "Total de fotos: " + photos.length + "\r\n\r\n" +
                        "DEDICATORIA / MENSAJE:\r\n" +
                        (comment ? comment : "(Sin mensaje de texto)") + "\r\n\r\n" +
                        "═══════════════════════════════════════════════════════";
    guestFolder.createFile("Dedicatoria_" + safeGuestName + ".txt", noteContent, "text/plain");

    // 4. Guardar cada una de las fotos
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

        const file = guestFolder.createFile(blob);
        file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);

        const fileId = file.getId();
        // URL directa de imagen que se puede mostrar en la web
        const directUrl = "https://lh3.googleusercontent.com/d/" + fileId;
        const viewUrl = file.getUrl();

        savedPhotos.push({
          name: fileName,
          id: fileId,
          url: directUrl,
          viewUrl: viewUrl
        });
      } catch (photoErr) {
        // Continuar con las demás fotos si una falla
        Logger.log("Error guardando foto " + i + ": " + photoErr.toString());
      }
    }

    // 5. Retornar respuesta exitosa
    return responseJSON({
      status: "success",
      message: "Recuerdos guardados exitosamente",
      guestName: guestName,
      comment: comment,
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
 * Maneja peticiones GET (para verificar conexión o listar recuerdos)
 */
function doGet(e) {
  try {
    const action = e && e.parameter ? e.parameter.action : "ping";

    if (action === "ping") {
      return responseJSON({
        status: "ok",
        message: "Backend de Google Drive / Fotos activo para 15 Años de Danna",
        time: new Date().toISOString()
      });
    }

    if (action === "list") {
      // Listar todas las carpetas y fotos
      const mainFolder = getOrCreateMainFolder(MAIN_FOLDER_NAME);
      const subfolders = mainFolder.getFolders();
      const memories = [];

      while (subfolders.hasNext()) {
        const folder = subfolders.next();
        const files = folder.getFiles();
        const photosList = [];
        var commentText = "";

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
          } else if (file.getName().indexOf("Dedicatoria") !== -1) {
            try {
              commentText = file.getBlob().getDataAsString();
            } catch(e) {}
          }
        }

        memories.push({
          folderId: folder.getId(),
          folderName: folder.getName(),
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
        memories: memories
      });
    }

    return responseJSON({ status: "error", message: "Acción no reconocida" });

  } catch (err) {
    return responseJSON({ status: "error", message: err.toString() });
  }
}

/**
 * Helper para obtener o crear la carpeta principal
 */
function getOrCreateMainFolder(folderName) {
  const folders = DriveApp.getFoldersByName(folderName);
  if (folders.hasNext()) {
    return folders.next();
  }
  const folder = DriveApp.createFolder(folderName);
  folder.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  return folder;
}

/**
 * Helper para retornar JSON con cabeceras CORS correctas
 */
function responseJSON(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
