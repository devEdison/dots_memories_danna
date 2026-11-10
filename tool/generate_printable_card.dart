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

  // Generar SVG nítido y elegante para el código QR
  final buffer = StringBuffer();
  final cellSize = 8;
  final margin = 4 * cellSize;
  final totalSize = moduleCount * cellSize + 2 * margin;

  buffer.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalSize $totalSize" width="100%" height="100%">');
  buffer.write('<rect width="100%" height="100%" fill="#FFFFFF" rx="14"/>');

  for (var r = 0; r < moduleCount; r++) {
    for (var c = 0; c < moduleCount; c++) {
      if (qrImage.isDark(r, c)) {
        final x = margin + c * cellSize;
        final y = margin + r * cellSize;
        buffer.write('<rect x="$x" y="$y" width="${cellSize - 0.5}" height="${cellSize - 0.5}" rx="1.5" fill="#334A38"/>');
      }
    }
  }

  // Corazón / flor decorativa en el centro
  final centerStart = (totalSize / 2) - 16;
  buffer.write('<rect x="$centerStart" y="$centerStart" width="32" height="32" rx="8" fill="#FFFFFF" stroke="#E598A8" stroke-width="1.8"/>');
  buffer.write('<text x="${totalSize / 2}" y="${totalSize / 2 + 6}" font-size="18" text-anchor="middle">🌸</text>');
  buffer.write('</svg>');
  final qrSvg = buffer.toString();

  final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Kit de Tarjetas de Mesa - Mis 15 Años Danna Alejandra 👑</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;1,400;1,600&family=Poppins:wght@300;400;500;600;700&display=swap');

    @page {
      size: letter portrait;
      margin: 8mm;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Poppins', sans-serif;
      background-color: #F4F7F4;
      color: #2D3748;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    /* Barra de visualización en pantalla */
    .no-print-bar {
      background: #334A38;
      color: white;
      padding: 16px 20px;
      text-align: center;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }

    .no-print-bar h2 {
      font-family: 'Playfair Display', serif;
      font-size: 18px;
      margin-bottom: 4px;
    }

    .no-print-bar p {
      font-size: 12px;
      color: #E2E8F0;
      margin-bottom: 10px;
    }

    .no-print-bar button {
      background: #E598A8;
      color: white;
      border: none;
      font-weight: 600;
      font-size: 14px;
      padding: 9px 22px;
      border-radius: 20px;
      cursor: pointer;
      margin: 0 6px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.15);
    }

    .page-sheet {
      max-width: 860px;
      margin: 20px auto;
      background: white;
      padding: 18px;
      box-shadow: 0 6px 20px rgba(0,0,0,0.06);
      border-radius: 12px;
      page-break-after: always;
    }

    .model-header {
      text-align: center;
      font-size: 11px;
      font-weight: 700;
      color: #5B7F67;
      text-transform: uppercase;
      letter-spacing: 0.8px;
      margin-bottom: 12px;
      padding-bottom: 4px;
      border-bottom: 1px dashed #D2DDD4;
    }

    /* ======================================================== */
    /* MODELO 1: CARPA DE MESA PLEGABLE (SE SOSTIENE SOLA)     */
    /* ======================================================== */
    .tent-card-wrapper {
      border: 2px dashed #D2DDD4;
      border-radius: 20px;
      padding: 14px;
      background: #FAFCFA;
    }

    .tent-face {
      border: 1.5px solid #D2DDD4;
      border-radius: 18px;
      padding: 18px 20px;
      text-align: center;
      background: linear-gradient(180deg, #FAFCFA 0%, #FFFFFF 60%, #FFF8FA 100%);
    }

    /* Doblez central para que la carpa se pare sola */
    .fold-line-divider {
      margin: 12px 0;
      text-align: center;
      position: relative;
    }

    .fold-line-bar {
      border-top: 2px dashed #B88E99;
      position: relative;
      top: 11px;
    }

    .fold-badge {
      background: #FFF0F3;
      border: 1px solid #E598A8;
      color: #9E4A5C;
      font-size: 10.5px;
      font-weight: 700;
      padding: 3px 16px;
      border-radius: 12px;
      display: inline-block;
      position: relative;
      z-index: 2;
    }

    .crown-icon {
      font-size: 32px;
      margin-bottom: 2px;
      display: inline-block;
      filter: drop-shadow(0 2px 4px rgba(229,152,168,0.3));
    }

    .title-main {
      font-family: 'Playfair Display', serif;
      font-size: 22px;
      font-weight: 700;
      color: #334A38;
      line-height: 1.2;
    }

    .title-sub {
      font-family: 'Playfair Display', serif;
      font-style: italic;
      font-size: 16px;
      color: #C05872;
      font-weight: 600;
      margin-bottom: 6px;
    }

    .tent-invitation {
      font-size: 11.5px;
      color: #4A5568;
      max-width: 520px;
      margin: 0 auto 10px auto;
      line-height: 1.45;
    }

    .tent-content-row {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 22px;
      margin-top: 6px;
    }

    .qr-box {
      width: 145px;
      height: 145px;
      background: white;
      padding: 8px;
      border-radius: 16px;
      border: 2px solid #EBD5DB;
      box-shadow: 0 4px 12px rgba(229,152,168,0.18);
      flex-shrink: 0;
    }

    .steps-col {
      text-align: left;
      font-size: 11.5px;
      color: #4A5568;
      line-height: 1.45;
    }

    .step-item {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 5px;
    }

    .step-badge {
      width: 20px;
      height: 20px;
      background: #E598A8;
      color: white;
      font-weight: 700;
      font-size: 11px;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .tent-footer {
      margin-top: 8px;
      padding-top: 6px;
      border-top: 1px solid #EDF2EE;
      font-size: 10px;
      color: #718096;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .tent-footer .quote {
      font-style: italic;
      color: #C05872;
      font-weight: 500;
    }

    .tip-box {
      margin-top: 10px;
      padding: 8px;
      background: #F7FAFC;
      border: 1px dashed #A0AEC0;
      border-radius: 10px;
      text-align: center;
      font-size: 10px;
      color: #718096;
    }

    /* ======================================================== */
    /* MODELO 2: TARJETITAS INDIVIDUALES (4 POR PÁGINA)        */
    /* ======================================================== */
    .mini-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
    }

    .mini-card {
      border: 1.5px dashed #D2DDD4;
      border-radius: 18px;
      padding: 16px 14px;
      text-align: center;
      background: linear-gradient(180deg, #FFFFFF 0%, #FFF9FA 100%);
    }

    .mini-title {
      font-family: 'Playfair Display', serif;
      font-size: 16px;
      font-weight: 700;
      color: #334A38;
    }

    .mini-sub {
      font-family: 'Playfair Display', serif;
      font-style: italic;
      font-size: 13px;
      color: #C05872;
      margin-bottom: 6px;
    }

    .mini-text {
      font-size: 10px;
      color: #4A5568;
      margin-bottom: 8px;
      line-height: 1.35;
    }

    .mini-qr {
      width: 120px;
      height: 120px;
      margin: 0 auto 8px auto;
      background: white;
      padding: 6px;
      border-radius: 12px;
      border: 1.5px solid #EBD5DB;
    }

    .mini-footer {
      font-size: 9.5px;
      color: #8C9E90;
      font-weight: 500;
    }

    @media print {
      body {
        background: white;
      }
      .no-print-bar {
        display: none !important;
      }
      .page-sheet {
        margin: 0;
        padding: 0;
        box-shadow: none;
        max-width: 100%;
        border-radius: 0;
      }
    }
  </style>
</head>
<body>

  <!-- BARRA DE ACCIÓN SUPERIOR -->
  <div class="no-print-bar">
    <h2>👑 Kit de Tarjetas Físicas de Mesa — Mis 15 Años Danna Alejandra</h2>
    <p>Incluye carpa plegable que se sostiene sola en el centro de la mesa y tarjetitas individuales para platos/copas.</p>
    <button onclick="window.print()">🖨️ Imprimir Kit Completo</button>
  </div>

  <!-- ========================================================= -->
  <!-- HOJA 1: CARPA DE MESA PLEGABLE (SE DETIENE SOLA)          -->
  <!-- ========================================================= -->
  <div class="page-sheet">
    <div class="model-header">
      📐 MODELO 1: CARPA DE MESA PLEGABLE (DOBLAR POR EL CENTRO PARA QUE SE SOSTENGA SOLA)
    </div>

    <div class="tent-card-wrapper">
      <!-- CARA 1 (CARA POSTERIOR) -->
      <div class="tent-face">
        <div class="crown-icon">👑</div>
        <div class="title-main">Mis 15 Años</div>
        <div class="title-sub">Danna Alejandra 🌸</div>
        <p class="tent-invitation">
          <strong>¡Ayúdanos a capturar cada momento mágico de esta noche!</strong><br>
          Cada sonrisa, abrazo y baile son recuerdos inolvidables para mí. Escanea este código QR con la cámara de tu celular y comparte todas tus fotos y videos en mi álbum oficial.
        </p>

        <div class="tent-content-row">
          <div class="qr-box">
            $qrSvg
          </div>
          <div class="steps-col">
            <div class="step-item">
              <span class="step-badge">1</span>
              <span>Abre la cámara de tu celular</span>
            </div>
            <div class="step-item">
              <span class="step-badge">2</span>
              <span>Apunta hacia el código QR</span>
            </div>
            <div class="step-item">
              <span class="step-badge">3</span>
              <span>Sube fotos, videos y déjame tu dedicatoria ✨</span>
            </div>
            <div style="margin-top: 8px; font-weight: 600; color: #334A38; font-size: 11px;">
              ¡No necesitas instalar ninguna aplicación! 📲
            </div>
          </div>
        </div>

        <div class="tent-footer">
          <span class="quote">"Los mejores recuerdos son aquellos que compartimos juntos" 💕</span>
          <span>Clave: <strong>$accessKey</strong></span>
        </div>
      </div>

      <!-- LÍNEA DE CORTE Y DOBLADO CENTRAL -->
      <div class="fold-line-divider">
        <div class="fold-line-bar"></div>
        <span class="fold-badge">✂️ DOBLAR POR ESTA LÍNEA PARA QUE SE PARE SOLA (CARPA DE MESA) ✂️</span>
      </div>

      <!-- CARA 2 (CARA FRONTAL) -->
      <div class="tent-face">
        <div class="crown-icon">👑</div>
        <div class="title-main">Mis 15 Años</div>
        <div class="title-sub">Danna Alejandra 🌸</div>
        <p class="tent-invitation">
          <strong>¡Ayúdanos a capturar cada momento mágico de esta noche!</strong><br>
          Cada sonrisa, abrazo y baile son recuerdos inolvidables para mí. Escanea este código QR con la cámara de tu celular y comparte todas tus fotos y videos en mi álbum oficial.
        </p>

        <div class="tent-content-row">
          <div class="qr-box">
            $qrSvg
          </div>
          <div class="steps-col">
            <div class="step-item">
              <span class="step-badge">1</span>
              <span>Abre la cámara de tu celular</span>
            </div>
            <div class="step-item">
              <span class="step-badge">2</span>
              <span>Apunta hacia el código QR</span>
            </div>
            <div class="step-item">
              <span class="step-badge">3</span>
              <span>Sube fotos, videos y déjame tu dedicatoria ✨</span>
            </div>
            <div style="margin-top: 8px; font-weight: 600; color: #334A38; font-size: 11px;">
              ¡No necesitas instalar ninguna aplicación! 📲
            </div>
          </div>
        </div>

        <div class="tent-footer">
          <span class="quote">"Gracias por celebrar conmigo este día inolvidable" 💖</span>
          <span>Clave: <strong>$accessKey</strong></span>
        </div>
      </div>

      <div class="tip-box">
        💡 <em>Instrucciones: Imprime en cartulina u opalina (180g a 240g), recorta por el borde exterior punteado y dobla firmemente por la línea central. Se mantendrá erguida sola en el centro de la mesa con vista por ambos lados.</em>
      </div>
    </div>
  </div>

  <!-- ========================================================= -->
  <!-- HOJA 2: TARJETITAS INDIVIDUALES DE MESA (4 POR HOJA)      -->
  <!-- ========================================================= -->
  <div class="page-sheet">
    <div class="model-header">
      ✂️ MODELO 2: MINI-TARJETITAS INDIVIDUALES (4 POR HOJA PARA CADA SERVICIO, PLATO O COPA)
    </div>

    <div class="mini-grid">
      <!-- Tarjetita 1 -->
      <div class="mini-card">
        <div style="font-size: 24px;">👑</div>
        <div class="mini-title">Mis 15 Años</div>
        <div class="mini-sub">Danna Alejandra 🌸</div>
        <p class="mini-text">
          ¡Guarda la magia de esta noche! Escanea el código QR con tu celular y sube todas tus fotos y dedicatoria.
        </p>
        <div class="mini-qr">
          $qrSvg
        </div>
        <div style="font-size: 9.5px; color: #4A5568; margin-bottom: 4px;">
          1. Abre tu cámara • 2. Escanea • 3. Sube tus fotos ✨
        </div>
        <div class="mini-footer">
          ¡Gracias por acompañarme! 💕
        </div>
      </div>

      <!-- Tarjetita 2 -->
      <div class="mini-card">
        <div style="font-size: 24px;">👑</div>
        <div class="mini-title">Mis 15 Años</div>
        <div class="mini-sub">Danna Alejandra 🌸</div>
        <p class="mini-text">
          ¡Guarda la magia de esta noche! Escanea el código QR con tu celular y sube todas tus fotos y dedicatoria.
        </p>
        <div class="mini-qr">
          $qrSvg
        </div>
        <div style="font-size: 9.5px; color: #4A5568; margin-bottom: 4px;">
          1. Abre tu cámara • 2. Escanea • 3. Sube tus fotos ✨
        </div>
        <div class="mini-footer">
          ¡Gracias por acompañarme! 💕
        </div>
      </div>

      <!-- Tarjetita 3 -->
      <div class="mini-card">
        <div style="font-size: 24px;">👑</div>
        <div class="mini-title">Mis 15 Años</div>
        <div class="mini-sub">Danna Alejandra 🌸</div>
        <p class="mini-text">
          ¡Guarda la magia de esta noche! Escanea el código QR con tu celular y sube todas tus fotos y dedicatoria.
        </p>
        <div class="mini-qr">
          $qrSvg
        </div>
        <div style="font-size: 9.5px; color: #4A5568; margin-bottom: 4px;">
          1. Abre tu cámara • 2. Escanea • 3. Sube tus fotos ✨
        </div>
        <div class="mini-footer">
          ¡Gracias por acompañarme! 💕
        </div>
      </div>

      <!-- Tarjetita 4 -->
      <div class="mini-card">
        <div style="font-size: 24px;">👑</div>
        <div class="mini-title">Mis 15 Años</div>
        <div class="mini-sub">Danna Alejandra 🌸</div>
        <p class="mini-text">
          ¡Guarda la magia de esta noche! Escanea el código QR con tu celular y sube todas tus fotos y dedicatoria.
        </p>
        <div class="mini-qr">
          $qrSvg
        </div>
        <div style="font-size: 9.5px; color: #4A5568; margin-bottom: 4px;">
          1. Abre tu cámara • 2. Escanea • 3. Sube tus fotos ✨
        </div>
        <div class="mini-footer">
          ¡Gracias por acompañarme! 💕
        </div>
      </div>
    </div>
  </div>

</body>
</html>
''';

  // Guardar archivos HTML
  File('tarjeta_mesa_qr.html').writeAsStringSync(html);
  File('web/tarjeta_mesa_qr.html').writeAsStringSync(html);
  print('HTML generado exitosamente en tarjeta_mesa_qr.html y web/tarjeta_mesa_qr.html');

  // Generar PDF usando Chrome headless
  const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  if (File(chromePath).existsSync()) {
    try {
      print('Generando PDF con Chrome headless...');
      final result = Process.runSync(
        chromePath,
        [
          '--headless',
          '--disable-gpu',
          '--no-pdf-header-footer',
          '--print-to-pdf=web/tarjeta_mesa_qr.pdf',
          'tarjeta_mesa_qr.html',
        ],
      );
      if (result.exitCode == 0) {
        File('web/tarjeta_mesa_qr.pdf').copySync('tarjeta_mesa_qr.pdf');
        print('🎉 ¡PDF generado con éxito en web/tarjeta_mesa_qr.pdf y tarjeta_mesa_qr.pdf!');
      } else {
        print('Aviso Chrome: \${result.stderr}');
      }
    } catch (e) {
      print('Aviso ejecutando Chrome: \$e');
    }
  }
}
