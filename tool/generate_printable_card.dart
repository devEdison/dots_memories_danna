// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'package:qr/qr.dart';

void main() {
  const accessUrl = 'https://danna15-memories.appwrite.network/?key=DANNA15';
  const accessKey = 'DANNA15';

  final qrCode = QrCode.fromData(
    data: accessUrl,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qrImage = QrImage(qrCode);
  final moduleCount = qrImage.moduleCount;

  // Generate SVG path for dark modules
  final buffer = StringBuffer();
  final cellSize = 8;
  final margin = 4 * cellSize;
  final totalSize = moduleCount * cellSize + 2 * margin;

  buffer.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalSize $totalSize" width="100%" height="100%">');
  buffer.write('<rect width="100%" height="100%" fill="#FFFFFF" rx="16"/>');

  for (var r = 0; r < moduleCount; r++) {
    for (var c = 0; c < moduleCount; c++) {
      if (qrImage.isDark(r, c)) {
        final x = margin + c * cellSize;
        final y = margin + r * cellSize;
        // Draw slightly rounded square for elegance
        buffer.write('<rect x="$x" y="$y" width="${cellSize - 0.5}" height="${cellSize - 0.5}" rx="1.5" fill="#334A38"/>');
      }
    }
  }

  // Draw decorative center heart or sparkles in SVG
  buffer.write('</svg>');
  final qrSvg = buffer.toString();

  // Create printable HTML
  final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Tarjetas de Mesa - Mis 15 Años Danna Alejandra 👑</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,400&family=Poppins:wght@300;400;500;600;700&display=swap');

    @page {
      size: letter portrait;
      margin: 10mm;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Poppins', sans-serif;
      background-color: #F3F4F6;
      color: #2D3748;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    .no-print-bar {
      background: #334A38;
      color: white;
      padding: 14px 20px;
      text-align: center;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
      position: sticky;
      top: 0;
      z-index: 100;
    }

    .no-print-bar button {
      background: #E598A8;
      color: white;
      border: none;
      font-weight: 600;
      font-size: 15px;
      padding: 10px 24px;
      border-radius: 20px;
      cursor: pointer;
      margin-left: 14px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.15);
      transition: background 0.2s;
    }

    .no-print-bar button:hover {
      background: #D47A8E;
    }

    .page-container {
      max-width: 900px;
      margin: 20px auto;
      padding: 10px;
    }

    /* Grid of 2 table cards per page (fits 2 5x7" or half-letter cards per sheet) */
    .cards-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20mm;
      justify-content: center;
    }

    @media (max-width: 768px) {
      .cards-grid {
        grid-template-columns: 1fr;
      }
    }

    .table-card {
      background: #FFFFFF;
      border: 2px solid #D2DDD4;
      border-radius: 24px;
      padding: 28px 24px;
      text-align: center;
      position: relative;
      box-shadow: 0 8px 24px rgba(110, 139, 116, 0.12);
      page-break-inside: avoid;
    }

    /* Elegant inner frame */
    .card-inner {
      border: 1px solid #EBD5DB;
      border-radius: 18px;
      padding: 20px 16px;
      background: linear-gradient(180deg, #FAFCFA 0%, #FFFFFF 60%, #FFF8FA 100%);
    }

    .crown-icon {
      font-size: 38px;
      margin-bottom: 6px;
      display: inline-block;
      filter: drop-shadow(0 2px 4px rgba(229,152,168,0.3));
    }

    .card-title {
      font-family: 'Playfair Display', serif;
      font-size: 26px;
      font-weight: 700;
      color: #334A38;
      margin-bottom: 4px;
      letter-spacing: -0.5px;
    }

    .card-subtitle {
      font-family: 'Playfair Display', serif;
      font-style: italic;
      font-size: 14px;
      color: #D47A8E;
      margin-bottom: 14px;
    }

    .instruction-badge {
      display: inline-block;
      background: #EAF2EC;
      color: #334A38;
      font-size: 11px;
      font-weight: 600;
      padding: 5px 14px;
      border-radius: 20px;
      border: 1px solid #D2DDD4;
      margin-bottom: 14px;
      text-transform: uppercase;
      letter-spacing: 0.8px;
    }

    .qr-container {
      width: 190px;
      height: 190px;
      margin: 0 auto 14px auto;
      background: white;
      padding: 10px;
      border-radius: 18px;
      border: 2px solid #EBD5DB;
      box-shadow: 0 4px 14px rgba(229,152,168,0.18);
    }

    .steps-list {
      text-align: left;
      font-size: 11.5px;
      color: #4A5568;
      margin: 12px auto;
      max-width: 260px;
      line-height: 1.5;
    }

    .step-item {
      display: flex;
      align-items: center;
      margin-bottom: 6px;
    }

    .step-num {
      background: #E598A8;
      color: white;
      font-weight: 700;
      font-size: 10px;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 8px;
      flex-shrink: 0;
    }

    .key-badge {
      display: inline-block;
      background: #F8FBF9;
      border: 1px solid #D2DDD4;
      border-radius: 12px;
      padding: 5px 12px;
      font-size: 11px;
      color: #334A38;
      font-weight: 600;
      margin-top: 6px;
    }

    .card-footer {
      font-size: 9.5px;
      color: #8C9E90;
      margin-top: 12px;
      letter-spacing: 0.5px;
    }

    @media print {
      body {
        background: white;
      }
      .no-print-bar {
        display: none !important;
      }
      .page-container {
        margin: 0;
        padding: 0;
        max-width: 100%;
      }
      .table-card {
        box-shadow: none !important;
        border: 1px solid #C4D2C7;
      }
    }
  </style>
</head>
<body>

  <div class="no-print-bar">
    <span>✨ <strong>Plantilla de Tarjetas Físicas de Mesa</strong> — Mis 15 Años Danna Alejandra</span>
    <button onclick="window.print()">🖨️ Imprimir Tarjetas Ahora</button>
  </div>

  <div class="page-container">
    <div class="cards-grid">
      <!-- Tarjeta 1 -->
      <div class="table-card">
        <div class="card-inner">
          <div class="crown-icon">👑</div>
          <h1 class="card-title">Mis 15 Años</h1>
          <div class="card-subtitle">Danna Alejandra 🌸</div>
          <div class="instruction-badge">Álbum Digital de Recuerdos</div>

          <div class="qr-container">
            $qrSvg
          </div>

          <div class="steps-list">
            <div class="step-item">
              <span class="step-num">1</span>
              <span>Abre la cámara de tu celular</span>
            </div>
            <div class="step-item">
              <span class="step-num">2</span>
              <span>Apunta hacia el código QR</span>
            </div>
            <div class="step-item">
              <span class="step-num">3</span>
              <span>Sube tus fotos, videos y dedicatoria ✨</span>
            </div>
          </div>

          <div class="key-badge">
            🔑 Clave de Acceso: <strong>$accessKey</strong>
          </div>

          <div class="card-footer">
            ¡Gracias por celebrar conmigo este día inolvidable! 💖
          </div>
        </div>
      </div>

      <!-- Tarjeta 2 -->
      <div class="table-card">
        <div class="card-inner">
          <div class="crown-icon">👑</div>
          <h1 class="card-title">Mis 15 Años</h1>
          <div class="card-subtitle">Danna Alejandra 🌸</div>
          <div class="instruction-badge">Álbum Digital de Recuerdos</div>

          <div class="qr-container">
            $qrSvg
          </div>

          <div class="steps-list">
            <div class="step-item">
              <span class="step-num">1</span>
              <span>Abre la cámara de tu celular</span>
            </div>
            <div class="step-item">
              <span class="step-num">2</span>
              <span>Apunta hacia el código QR</span>
            </div>
            <div class="step-item">
              <span class="step-num">3</span>
              <span>Sube tus fotos, videos y dedicatoria ✨</span>
            </div>
          </div>

          <div class="key-badge">
            🔑 Clave de Acceso: <strong>$accessKey</strong>
          </div>

          <div class="card-footer">
            ¡Gracias por celebrar conmigo este día inolvidable! 💖
          </div>
        </div>
      </div>
    </div>
  </div>

</body>
</html>
''';

  // Write file to workspace root and to web/ so it's directly accessible online as well
  File('tarjeta_mesa_qr.html').writeAsStringSync(html);
  File('web/tarjeta_mesa_qr.html').writeAsStringSync(html);
  print('HTML generado exitosamente en tarjeta_mesa_qr.html y web/tarjeta_mesa_qr.html');
}
