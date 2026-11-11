// Backend Security Tests for google_apps_script/Code.js executed under macOS JavaScriptCore (jsc)

var mockLogs = [];
var Logger = {
  log: function (msg) {
    mockLogs.push(String(msg));
  }
};

var Session = {
  getScriptTimeZone: function () {
    return "America/Guatemala";
  }
};

var Utilities = {
  formatDate: function () {
    return "2026-11-11_01-00";
  },
  base64Decode: function (b64) {
    return String(b64 || "");
  },
  newBlob: function (bytes, mimeType, name) {
    return {
      bytes: bytes,
      mimeType: mimeType || "application/octet-stream",
      name: name || "blob.bin"
    };
  }
};

var ContentService = {
  MimeType: { JSON: "application/json" },
  createTextOutput: function (text) {
    return {
      getContent: function () {
        return text;
      },
      setMimeType: function () {
        return this;
      }
    };
  }
};

var mockScriptProps = {};
var PropertiesService = {
  getScriptProperties: function () {
    return {
      getProperty: function (key) {
        return Object.prototype.hasOwnProperty.call(mockScriptProps, key)
          ? mockScriptProps[key]
          : null;
      }
    };
  }
};

var LockService = {
  getScriptLock: function () {
    return {
      tryLock: function () {
        return true;
      },
      releaseLock: function () {}
    };
  }
};

var UrlFetchApp = {
  fetch: function () {
    return {
      getResponseCode: function () {
        return 403;
      },
      getContentText: function () {
        return "";
      }
    };
  }
};

function makeIterator(items) {
  var idx = 0;
  return {
    hasNext: function () {
      return idx < items.length;
    },
    next: function () {
      return items[idx++];
    }
  };
}

var driveState = {};

function makeFileObj(id, name, mime, parentFolder) {
  var trashed = false;
  var content = "";
  var fileObj = {
    getId: function () {
      return id;
    },
    getName: function () {
      return name;
    },
    getMimeType: function () {
      return mime;
    },
    getUrl: function () {
      return "https://drive.google.com/file/d/" + id + "/view";
    },
    setSharing: function () {},
    setContent: function (c) {
      content = c;
    },
    isTrashed: function () {
      return trashed;
    },
    setTrashed: function (flag) {
      trashed = Boolean(flag);
    },
    getParents: function () {
      return makeIterator(parentFolder ? [parentFolder] : []);
    },
    getBlob: function () {
      return {
        getDataAsString: function () {
          return content;
        }
      };
    }
  };
  driveState.files[id] = fileObj;
  return fileObj;
}

function makeFolderObj(id, name, parentFolder, initialDesc) {
  var description = initialDesc || "";
  var trashed = false;
  var childFolders = [];
  var childFiles = [];
  var created = new Date("2026-11-10T18:00:00Z");

  var folderObj = {
    getId: function () {
      return id;
    },
    getName: function () {
      return name;
    },
    getUrl: function () {
      return "https://drive.google.com/drive/folders/" + id;
    },
    getDescription: function () {
      return description;
    },
    setDescription: function (d) {
      description = d;
    },
    setSharing: function () {},
    isTrashed: function () {
      return trashed;
    },
    setTrashed: function (flag) {
      trashed = Boolean(flag);
    },
    getDateCreated: function () {
      return created;
    },
    getParents: function () {
      return makeIterator(parentFolder ? [parentFolder] : []);
    },
    getFolders: function () {
      return makeIterator(childFolders.filter(function (f) { return !f.isTrashed(); }));
    },
    createFolder: function (subName) {
      var newId = "folder_gen_" + (++driveState.seq);
      var sub = makeFolderObj(newId, subName, folderObj, "");
      childFolders.push(sub);
      return sub;
    },
    _addChildFolder: function (sub) {
      childFolders.push(sub);
    },
    getFiles: function () {
      return makeIterator(childFiles.filter(function (f) { return !f.isTrashed(); }));
    },
    getFilesByName: function (targetName) {
      return makeIterator(childFiles.filter(function (f) {
        return !f.isTrashed() && f.getName() === targetName;
      }));
    },
    createFile: function (arg1, arg2, arg3) {
      var fId = "file_gen_" + (++driveState.seq);
      var fName = typeof arg1 === "string" ? arg1 : arg1.name;
      var fMime = typeof arg1 === "string" ? (arg3 || "text/plain") : arg1.mimeType;
      var f = makeFileObj(fId, fName, fMime, folderObj);
      if (typeof arg2 === "string") {
        f.setContent(arg2);
      }
      childFiles.push(f);
      return f;
    },
    _addFile: function (f) {
      childFiles.push(f);
    }
  };
  driveState.folders[id] = folderObj;
  return folderObj;
}

var DriveApp = {
  Access: { ANYONE_WITH_LINK: "ANYONE_WITH_LINK" },
  Permission: { VIEW: "VIEW" },
  getFoldersByName: function (name) {
    var list = [];
    for (var k in driveState.folders) {
      if (driveState.folders[k].getName() === name && !driveState.folders[k].isTrashed()) {
        list.push(driveState.folders[k]);
      }
    }
    return makeIterator(list);
  },
  getFolderById: function (id) {
    if (!driveState.folders[id]) {
      throw new Error("Folder not found: " + id);
    }
    return driveState.folders[id];
  },
  getFileById: function (id) {
    if (!driveState.files[id]) {
      throw new Error("File not found: " + id);
    }
    return driveState.files[id];
  },
  createFolder: function (name) {
    var newId = "folder_root_" + (++driveState.seq);
    return makeFolderObj(newId, name, null, "");
  }
};

function resetDriveFixture() {
  mockLogs = [];
  mockScriptProps = {};
  driveState = { seq: 0, folders: {}, files: {} };

  var mainFolder = makeFolderObj("main_folder_1", "15 Años Danna - Fotos de Invitados", null, "");
  var outsideFolder = makeFolderObj("outside_private_folder", "Carpeta Privada", null, "");

  var carlosFolder = makeFolderObj(
    "folder_carlos",
    "Carlos (2026-11-10_20-00)",
    mainFolder,
    JSON.stringify({
      guestName: "Carlos",
      comment: "Felicidades",
      deviceId: "dev_carlos",
      photos: [
        { name: "carlos_1.jpg", id: "file_carlos_1" },
        { name: "carlos_2.jpg", id: "file_carlos_2" }
      ]
    })
  );
  mainFolder._addChildFolder(carlosFolder);

  var carlosPhoto1 = makeFileObj("file_carlos_1", "carlos_1.jpg", "image/jpeg", carlosFolder);
  var carlosPhoto2 = makeFileObj("file_carlos_2", "carlos_2.jpg", "image/jpeg", carlosFolder);
  var carlosDedication = makeFileObj("file_carlos_txt", "Dedicatoria_Carlos.txt", "text/plain", carlosFolder);
  carlosFolder._addFile(carlosPhoto1);
  carlosFolder._addFile(carlosPhoto2);
  carlosFolder._addFile(carlosDedication);

  var anaFolder = makeFolderObj(
    "folder_ana",
    "Ana (2026-11-10_20-10)",
    mainFolder,
    JSON.stringify({
      guestName: "Ana",
      comment: "Te quiero mucho",
      deviceId: "dev_ana",
      photos: [{ name: "ana_1.jpg", id: "file_ana_1" }]
    })
  );
  mainFolder._addChildFolder(anaFolder);
  var anaPhoto1 = makeFileObj("file_ana_1", "ana_1.jpg", "image/jpeg", anaFolder);
  anaFolder._addFile(anaPhoto1);

  return {
    mainFolder: mainFolder,
    outsideFolder: outsideFolder,
    carlosFolder: carlosFolder,
    carlosPhoto1: carlosPhoto1,
    carlosPhoto2: carlosPhoto2,
    carlosDedication: carlosDedication,
    anaFolder: anaFolder,
    anaPhoto1: anaPhoto1
  };
}

function assert(cond, msg) {
  if (!cond) {
    throw new Error("SECURITY ASSERTION FAILED: " + msg);
  }
}

function invokePost(payloadObj) {
  var out = doPost({
    postData: { contents: JSON.stringify(payloadObj) }
  });
  return JSON.parse(out.getContent());
}

// Load production Google Apps Script file
load("google_apps_script/Code.js");

var passed = 0;
function runTest(name, fn) {
  fn();
  passed++;
  print("PASS [Code.js security] " + name);
}

runTest("1. Bloquea deleteFolder si role no es admin", function () {
  var f = resetDriveFixture();
  var res = invokePost({
    action: "deleteFolder",
    role: "guest",
    folderId: "folder_carlos",
    deviceId: "dev_carlos"
  });
  assert(res.status === "error" && res.code === 403, "Expected 403 error");
  assert(!f.carlosFolder.isTrashed(), "Victim folder must NOT be trashed");
});

runTest("2. Bloquea deleteFolder si ADMIN_SECRET está configurado y no coincide", function () {
  var f = resetDriveFixture();
  mockScriptProps.ADMIN_SECRET = "super_secreto_danna";
  var res = invokePost({
    action: "deleteFolder",
    role: "admin",
    adminSecret: "intento_invalido",
    folderId: "folder_carlos"
  });
  assert(res.status === "error" && res.code === 403, "Expected 403 when adminSecret mismatches");
  assert(!f.carlosFolder.isTrashed(), "Folder must NOT be trashed without valid adminSecret");
});

runTest("3. Bloquea deleteFile si un invitado intenta borrar foto de otro dispositivo", function () {
  var f = resetDriveFixture();
  var res = invokePost({
    action: "deleteFile",
    role: "guest",
    fileId: "file_carlos_1",
    folderId: "folder_carlos",
    deviceId: "dev_attacker"
  });
  assert(res.status === "error" && res.code === 403, "Expected 403 IDOR block");
  assert(!f.carlosPhoto1.isTrashed(), "Carlos photo must NOT be trashed by dev_attacker");
});

runTest("4. Bloquea deleteFile si falta deviceId siendo invitado", function () {
  var f = resetDriveFixture();
  var res = invokePost({
    action: "deleteFile",
    fileId: "file_carlos_1"
  });
  assert(res.status === "error" && res.code === 403, "Expected 403 without deviceId");
  assert(!f.carlosPhoto1.isTrashed(), "Carlos photo must NOT be trashed");
});

runTest("5. Bloquea eliminar Dedicatoria_*.txt incluso del propio invitado o admin", function () {
  var f = resetDriveFixture();
  var res = invokePost({
    action: "deleteFile",
    role: "guest",
    fileId: "file_carlos_txt",
    folderId: "folder_carlos",
    deviceId: "dev_carlos"
  });
  assert(res.status === "error" && res.code === 403, "Expected 403 protecting dedication text");
  assert(!f.carlosDedication.isTrashed(), "Dedication file must NOT be trashed");
});

runTest("6. Permite al invitado borrar su propia foto y actualiza metadatos de caché", function () {
  var f = resetDriveFixture();
  var res = invokePost({
    action: "deleteFile",
    role: "guest",
    fileId: "file_carlos_1",
    folderId: "folder_carlos",
    deviceId: "dev_carlos"
  });
  assert(res.status === "success" && res.action === "deleteFile", "Expected success deleting own photo");
  assert(f.carlosPhoto1.isTrashed(), "Own photo should be trashed");
  var updatedMeta = JSON.parse(f.carlosFolder.getDescription());
  assert(updatedMeta.photos.length === 1 && updatedMeta.photos[0].id === "file_carlos_2", "Cache must drop only carlos_1");
});

runTest("7. Admin autorizado puede eliminar foto no permitida y carpeta completa", function () {
  var f = resetDriveFixture();
  var photoRes = invokePost({
    action: "deleteFile",
    role: "admin",
    fileId: "file_ana_1",
    folderId: "folder_ana"
  });
  assert(photoRes.status === "success" && f.anaPhoto1.isTrashed(), "Admin should trash unpermitted photo");

  var folderRes = invokePost({
    action: "deleteFolder",
    role: "admin",
    folderId: "folder_carlos"
  });
  assert(folderRes.status === "success" && f.carlosFolder.isTrashed(), "Admin should trash folder");
});

runTest("8. Subida bloquea escritura en carpeta ajena o fuera de carpeta principal y filtra archivos HTML/JS", function () {
  var f = resetDriveFixture();
  // Intenta subir apuntando a una carpeta privada fuera de mainFolder y con payload HTML
  var res = invokePost({
    guestName: "Carlos",
    comment: "Sobrescritura maliciosa",
    deviceId: "dev_attacker",
    folderId: "outside_private_folder",
    photos: [
      { name: "xss.html", type: "text/html", base64: "PHNjcmlwdD4=" },
      { name: "legit.jpg", type: "image/jpeg", base64: "AQID" }
    ]
  });
  assert(res.status === "success", "Should isolate into attacker folder, not crash");
  assert(res.folderId !== "outside_private_folder", "Must NOT write into folder outside main event directory");
  assert(res.folderId !== "folder_carlos", "Must NOT overwrite dev_carlos folder despite matching name Carlos");
  assert(f.outsideFolder.getFiles().hasNext() === false, "Outside folder must remain empty");
  assert(f.carlosFolder.getDescription().indexOf("Sobrescritura maliciosa") === -1, "Carlos metadata must remain untouched");
  assert(res.photos.length === 1 && res.photos[0].name === "legit.jpg", "HTML payload must be dropped, only legit image saved");
});

print("ALL " + passed + " CODE.JS SECURITY TESTS PASSED!");

