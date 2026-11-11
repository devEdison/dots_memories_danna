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

  // Generar SVG nítido para el QR en Verde Salvia profundo y flor vectorial Rosado + Dorado al centro
  final buffer = StringBuffer();
  final cellSize = 8;
  final margin = 4 * cellSize;
  final totalSize = moduleCount * cellSize + 2 * margin;
  final center = totalSize / 2;

  buffer.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalSize $totalSize" width="100%" height="100%">');
  buffer.write('<rect width="100%" height="100%" fill="#FFFFFF" rx="14"/>');

  for (var r = 0; r < moduleCount; r++) {
    for (var c = 0; c < moduleCount; c++) {
      if (qrImage.isDark(r, c)) {
        final x = margin + c * cellSize;
        final y = margin + r * cellSize;
        buffer.write('<rect x="$x" y="$y" width="${cellSize - 0.5}" height="${cellSize - 0.5}" rx="1.6" fill="#2A422F"/>');
      }
    }
  }

  // Medallón central vectorial: fondo blanco + borde dorado + flor rosada con centro dorado
  final centerStart = center - 17;
  buffer.write('<rect x="$centerStart" y="$centerStart" width="34" height="34" rx="10" fill="#FFFDF8" stroke="#D4AF37" stroke-width="2.4"/>');
  buffer.write('<circle cx="$center" cy="${center - 7}" r="5.2" fill="#E598A8"/>');
  buffer.write('<circle cx="${center + 6.6}" cy="${center - 2.2}" r="5.2" fill="#F0AEB9"/>');
  buffer.write('<circle cx="${center + 4.1}" cy="${center + 5.7}" r="5.2" fill="#CF7B8D"/>');
  buffer.write('<circle cx="${center - 4.1}" cy="${center + 5.7}" r="5.2" fill="#E598A8"/>');
  buffer.write('<circle cx="${center - 6.6}" cy="${center - 2.2}" r="5.2" fill="#F0AEB9"/>');
  buffer.write('<circle cx="$center" cy="$center" r="4.2" fill="#F5DE8C" stroke="#B88B1D" stroke-width="1.2"/>');
  buffer.write('</svg>');
  final qrSvg = buffer.toString();

  // Iconos vectoriales nítidos (100% vectoriales, cero fallos de fuentes bitmap al imprimir)
  const crownSvg = '''
  <svg viewBox="0 0 36 32" width="24" height="22" xmlns="http://www.w3.org/2000/svg">
    <path d="M4 23 L2 9 L10 15 L18 4 L26 15 L34 9 L32 23 Z" fill="#D4AF37" stroke="#8C6718" stroke-width="1.4" stroke-linejoin="round"/>
    <rect x="4" y="23" width="28" height="4" rx="2" fill="#A88225" stroke="#8C6718" stroke-width="1"/>
    <circle cx="18" cy="4" r="2.2" fill="#E598A8" stroke="#8C6718" stroke-width="0.9"/>
    <circle cx="2" cy="9" r="1.8" fill="#FFF4C2" stroke="#8C6718" stroke-width="0.9"/>
    <circle cx="34" cy="9" r="1.8" fill="#FFF4C2" stroke="#8C6718" stroke-width="0.9"/>
    <circle cx="18" cy="18" r="2.2" fill="#CF7B8D"/>
    <circle cx="11" cy="19" r="1.6" fill="#4B6651"/>
    <circle cx="25" cy="19" r="1.6" fill="#4B6651"/>
  </svg>''';

  const miniCrownSvg = '''
  <svg viewBox="0 0 36 32" width="20" height="18" xmlns="http://www.w3.org/2000/svg">
    <path d="M4 23 L2 9 L10 15 L18 4 L26 15 L34 9 L32 23 Z" fill="#D4AF37" stroke="#8C6718" stroke-width="1.5" stroke-linejoin="round"/>
    <rect x="4" y="23" width="28" height="4" rx="2" fill="#A88225" stroke="#8C6718" stroke-width="1"/>
    <circle cx="18" cy="4" r="2.2" fill="#E598A8"/>
    <circle cx="18" cy="18" r="2" fill="#CF7B8D"/>
  </svg>''';

  const floralDividerSvg = '''
  <svg viewBox="0 0 120 24" width="108" height="22" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="22" cy="12" rx="11" ry="4.5" fill="#6E8B74"/>
    <ellipse cx="32" cy="8" rx="6" ry="3" fill="#89A68E"/>
    <path d="M44 12 L46 7 L48 12 L53 14 L48 16 L46 21 L44 16 L39 14 Z" fill="#D4AF37"/>
    <circle cx="60" cy="7.5" r="3.8" fill="#E598A8"/>
    <circle cx="64.5" cy="10.8" r="3.8" fill="#F2BAC6"/>
    <circle cx="62.8" cy="15.8" r="3.8" fill="#CF7B8D"/>
    <circle cx="57.2" cy="15.8" r="3.8" fill="#E598A8"/>
    <circle cx="55.5" cy="10.8" r="3.8" fill="#F2BAC6"/>
    <circle cx="60" cy="12" r="2.8" fill="#F5DE8C" stroke="#B88B1D" stroke-width="0.9"/>
    <path d="M74 12 L76 7 L78 12 L83 14 L78 16 L76 21 L74 16 L69 14 Z" fill="#D4AF37"/>
    <ellipse cx="98" cy="12" rx="11" ry="4.5" fill="#6E8B74"/>
    <ellipse cx="88" cy="8" rx="6" ry="3" fill="#89A68E"/>
  </svg>''';

  // Ornamentos SVG botánicos de esquina (Verde Salvia, Rosado y Destellos Dorados)
  const cornerFloralTL = '''
  <svg class="floral-corner floral-tl" viewBox="0 0 90 90" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="26" cy="14" rx="16" ry="7" fill="#6E8B74" opacity="0.9"/>
    <ellipse cx="14" cy="28" rx="7" ry="15" fill="#4B6651" opacity="0.92"/>
    <ellipse cx="38" cy="24" rx="12" ry="5.5" fill="#89A68E" opacity="0.85"/>
    <ellipse cx="22" cy="40" rx="5.5" ry="11" fill="#89A68E" opacity="0.85"/>
    <circle cx="19" cy="19" r="9" fill="#E598A8"/>
    <circle cx="25" cy="16" r="6" fill="#F2BAC6"/>
    <circle cx="16" cy="25" r="6" fill="#CF7B8D"/>
    <circle cx="20" cy="20" r="3.2" fill="#F5DE8C" stroke="#D4AF37" stroke-width="1"/>
    <circle cx="48" cy="12" r="2.2" fill="#D4AF37"/>
    <circle cx="12" cy="50" r="2.2" fill="#D4AF37"/>
    <path d="M58 20 L60 14 L62 20 L68 22 L62 24 L60 30 L58 24 L52 22 Z" fill="#D4AF37"/>
    <path d="M22 60 L23.5 56 L25 60 L29 61.5 L25 63 L23.5 67 L22 63 L18 61.5 Z" fill="#D4AF37"/>
  </svg>''';

  const cornerFloralTR = '''
  <svg class="floral-corner floral-tr" viewBox="0 0 90 90" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="64" cy="14" rx="16" ry="7" fill="#6E8B74" opacity="0.9"/>
    <ellipse cx="76" cy="28" rx="7" ry="15" fill="#4B6651" opacity="0.92"/>
    <ellipse cx="52" cy="24" rx="12" ry="5.5" fill="#89A68E" opacity="0.85"/>
    <ellipse cx="68" cy="40" rx="5.5" ry="11" fill="#89A68E" opacity="0.85"/>
    <circle cx="71" cy="19" r="9" fill="#E598A8"/>
    <circle cx="65" cy="16" r="6" fill="#F2BAC6"/>
    <circle cx="74" cy="25" r="6" fill="#CF7B8D"/>
    <circle cx="70" cy="20" r="3.2" fill="#F5DE8C" stroke="#D4AF37" stroke-width="1"/>
    <circle cx="42" cy="12" r="2.2" fill="#D4AF37"/>
    <circle cx="78" cy="50" r="2.2" fill="#D4AF37"/>
    <path d="M30 20 L32 14 L34 20 L40 22 L34 24 L32 30 L30 24 L24 22 Z" fill="#D4AF37"/>
    <path d="M66 60 L67.5 56 L69 60 L73 61.5 L69 63 L67.5 67 L66 63 L62 61.5 Z" fill="#D4AF37"/>
  </svg>''';

  const cornerFloralBL = '''
  <svg class="floral-corner floral-bl" viewBox="0 0 90 90" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="26" cy="76" rx="16" ry="7" fill="#6E8B74" opacity="0.9"/>
    <ellipse cx="14" cy="62" rx="7" ry="15" fill="#4B6651" opacity="0.92"/>
    <ellipse cx="38" cy="66" rx="12" ry="5.5" fill="#89A68E" opacity="0.85"/>
    <ellipse cx="22" cy="50" rx="5.5" ry="11" fill="#89A68E" opacity="0.85"/>
    <circle cx="19" cy="71" r="9" fill="#E598A8"/>
    <circle cx="25" cy="74" r="6" fill="#F2BAC6"/>
    <circle cx="16" cy="65" r="6" fill="#CF7B8D"/>
    <circle cx="20" cy="70" r="3.2" fill="#F5DE8C" stroke="#D4AF37" stroke-width="1"/>
    <circle cx="48" cy="78" r="2.2" fill="#D4AF37"/>
    <circle cx="12" cy="40" r="2.2" fill="#D4AF37"/>
    <path d="M58 68 L60 62 L62 68 L68 70 L62 72 L60 78 L58 72 L52 70 Z" fill="#D4AF37"/>
  </svg>''';

  const cornerFloralBR = '''
  <svg class="floral-corner floral-br" viewBox="0 0 90 90" width="64" height="64" xmlns="http://www.w3.org/2000/svg">
    <ellipse cx="64" cy="76" rx="16" ry="7" fill="#6E8B74" opacity="0.9"/>
    <ellipse cx="76" cy="62" rx="7" ry="15" fill="#4B6651" opacity="0.92"/>
    <ellipse cx="52" cy="66" rx="12" ry="5.5" fill="#89A68E" opacity="0.85"/>
    <ellipse cx="68" cy="50" rx="5.5" ry="11" fill="#89A68E" opacity="0.85"/>
    <circle cx="71" cy="71" r="9" fill="#E598A8"/>
    <circle cx="65" cy="74" r="6" fill="#F2BAC6"/>
    <circle cx="74" cy="65" r="6" fill="#CF7B8D"/>
    <circle cx="70" cy="70" r="3.2" fill="#F5DE8C" stroke="#D4AF37" stroke-width="1"/>
    <circle cx="42" cy="78" r="2.2" fill="#D4AF37"/>
    <circle cx="78" cy="40" r="2.2" fill="#D4AF37"/>
    <path d="M30 68 L32 62 L34 68 L40 70 L34 72 L32 78 L30 72 L24 70 Z" fill="#D4AF37"/>
  </svg>''';

  String buildTentFace(String footerQuote) => '''
      <div class="tent-sage-frame">
        <div class="tent-face">
          $cornerFloralTL
          $cornerFloralTR
          $cornerFloralBL
          $cornerFloralBR

          <div class="top-gala-badge">✦ CELEBRACIÓN ESPECIAL ✦</div>
          <div class="crown-emblem">$crownSvg</div>
          <div class="title-main">Mis 15 Años</div>
          <div class="title-sub">Danna Alejandra</div>

          <div class="floral-divider">
            <div class="line"></div>
            $floralDividerSvg
            <div class="line"></div>
          </div>

          <p class="tent-invitation">
            <strong>¡Ayúdanos a capturar cada momento mágico de esta noche!</strong><br>
            Cada sonrisa, abrazo y baile son recuerdos inolvidables. Escanea este código QR y comparte todas tus fotos y videos en mi álbum oficial.
          </p>

          <div class="tent-content-row">
            <div class="qr-wrapper">
              <div class="qr-box">
                $qrSvg
              </div>
              <div class="qr-ribbon">✦ ¡ESCANEA AQUÍ! ✦</div>
            </div>
            <div class="steps-card">
              <div class="step-item">
                <span class="step-badge step-sage">1</span>
                <span>Abre la cámara de tu celular</span>
              </div>
              <div class="step-item">
                <span class="step-badge step-pink">2</span>
                <span>Apunta hacia el código QR</span>
              </div>
              <div class="step-item">
                <span class="step-badge step-gold">3</span>
                <span>Sube fotos, videos y tu dedicatoria ✦</span>
              </div>
              <div class="no-app-pill">
                ¡Sin instalar ninguna aplicación!
              </div>
            </div>
          </div>

          <div class="tent-footer">
            <span class="quote">"$footerQuote" ♥</span>
            <span class="key-pill">✦ Clave: <strong>$accessKey</strong></span>
          </div>
        </div>
      </div>''';

  final miniCardHtml = '''
      <div class="mini-cut-cell">
        <div class="mini-sage-frame">
          <div class="mini-card">
            $cornerFloralTL
            $cornerFloralTR

            <div class="mini-top-pill">✦ MIS 15 AÑOS ✦</div>
            <div class="mini-crown-wrap">$miniCrownSvg</div>
            <div class="mini-title">Danna Alejandra</div>
            <div class="mini-divider">$floralDividerSvg</div>
            <p class="mini-text">
              ¡Guarda la magia de esta noche! Escanea el código QR y sube tus fotos, videos y dedicatoria.
            </p>
            <div class="mini-qr-bezel">
              <div class="mini-qr">
                $qrSvg
              </div>
            </div>
            <div class="mini-steps">
              1. Cámara • 2. Escanea • 3. Sube fotos ✦
            </div>
            <div class="mini-footer">
              <span>♥ ¡Gracias por acompañarme!</span>
              <span class="mini-key">Clave: $accessKey</span>
            </div>
          </div>
        </div>
      </div>''';

  final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Kit de Tarjetas de Mesa - Mis 15 Años Danna Alejandra</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,500;0,700;0,800;1,400;1,600&family=Poppins:wght@400;500;600;700;800&display=swap');

    @page {
      size: letter portrait;
      margin: 6mm;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Poppins', sans-serif;
      background: linear-gradient(135deg, #DCE7DD 0%, #F7EFF2 50%, #F4EEDB 100%);
      color: #243527;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    /* Barra superior de acción web */
    .no-print-bar {
      background: linear-gradient(135deg, #2D4632 0%, #4A6850 55%, #2D4632 100%);
      color: white;
      padding: 16px 20px;
      text-align: center;
      position: sticky;
      top: 0;
      z-index: 100;
      border-bottom: 3px solid #D4AF37;
      box-shadow: 0 4px 16px rgba(0,0,0,0.22);
    }

    .no-print-bar h2 {
      font-family: 'Playfair Display', serif;
      font-size: 20px;
      margin-bottom: 4px;
      color: #FBE9A6;
      text-shadow: 0 1px 4px rgba(0,0,0,0.3);
    }

    .no-print-bar p {
      font-size: 12px;
      color: #EBF4EC;
      margin-bottom: 12px;
    }

    .no-print-bar button {
      background: linear-gradient(135deg, #F7E4A3 0%, #D4AF37 55%, #A67E1E 100%);
      color: #213224;
      border: 1.5px solid #FFF3C4;
      font-weight: 800;
      font-size: 14px;
      padding: 10px 26px;
      border-radius: 24px;
      cursor: pointer;
      margin: 0 6px;
      box-shadow: 0 4px 12px rgba(212, 175, 55, 0.35);
    }

    .page-sheet {
      max-width: 850px;
      margin: 18px auto;
      background: white;
      padding: 12px;
      border-radius: 16px;
      page-break-after: always;
    }

    .page-sheet-last {
      page-break-after: auto;
    }

    .model-header {
      text-align: center;
      font-size: 10.5px;
      font-weight: 700;
      color: #2F4B34;
      text-transform: uppercase;
      letter-spacing: 0.9px;
      margin-bottom: 8px;
      padding: 4px 10px;
      background: linear-gradient(90deg, #E2EFE4, #FDEAF0, #FCF5DF, #E2EFE4);
      border-radius: 10px;
      border: 1.2px solid #D4AF37;
    }

    /* ======================================================== */
    /* MODELO 1: CARPA DE MESA PLEGABLE (VERDE SALVIA DOMINANTE)*/
    /* ======================================================== */
    .tent-card-wrapper {
      border: 2px dashed #6E8B74;
      border-radius: 22px;
      padding: 7px;
      background: #F4F8F4;
    }

    .tent-sage-frame {
      background: linear-gradient(145deg, #4B6651 0%, #6E8B74 48%, #47624D 100%);
      padding: 8px;
      border-radius: 20px;
      border: 2px solid #D4AF37;
    }

    .tent-face {
      border: 2px solid #E8C96B;
      border-radius: 15px;
      padding: 9px 18px;
      text-align: center;
      background:
        radial-gradient(circle at 12% 15%, rgba(110, 139, 116, 0.24) 0%, transparent 42%),
        radial-gradient(circle at 88% 85%, rgba(229, 152, 168, 0.30) 0%, transparent 46%),
        radial-gradient(circle at 85% 18%, rgba(212, 175, 55, 0.22) 0%, transparent 40%),
        linear-gradient(180deg, #E2EEE4 0%, #F7FBF8 44%, #FCE9EF 100%);
      position: relative;
      overflow: hidden;
    }

    .floral-corner {
      position: absolute;
      pointer-events: none;
      z-index: 1;
    }
    .floral-tl { top: 2px; left: 2px; }
    .floral-tr { top: 2px; right: 2px; }
    .floral-bl { bottom: 2px; left: 2px; width: 46px; height: 46px; }
    .floral-br { bottom: 2px; right: 2px; width: 46px; height: 46px; }

    .top-gala-badge {
      display: inline-block;
      background: linear-gradient(90deg, #4B6651 0%, #C59B27 50%, #C25E75 100%);
      color: #FFFFFF;
      font-size: 9px;
      font-weight: 700;
      letter-spacing: 1.4px;
      padding: 2.5px 15px;
      border-radius: 20px;
      border: 1.5px solid #F6E4A7;
      margin-bottom: 4px;
      position: relative;
      z-index: 2;
    }

    .crown-emblem {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 38px;
      height: 38px;
      background: linear-gradient(135deg, #FFF5D1 0%, #F4DA84 48%, #C89F28 100%);
      border: 2px solid #FFFFFF;
      outline: 1.5px solid #D4AF37;
      border-radius: 50%;
      margin: 0 auto 3px auto;
      position: relative;
      z-index: 2;
    }

    .title-main {
      font-family: 'Playfair Display', serif;
      font-size: 20px;
      font-weight: 800;
      color: #2A422F;
      line-height: 1.15;
      position: relative;
      z-index: 2;
    }

    .title-sub {
      font-family: 'Playfair Display', serif;
      font-style: italic;
      font-size: 19px;
      color: #B43D59;
      font-weight: 800;
      margin-bottom: 2px;
      position: relative;
      z-index: 2;
    }

    .floral-divider {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      margin-bottom: 4px;
      position: relative;
      z-index: 2;
    }

    .floral-divider .line {
      height: 1.8px;
      width: 55px;
      background: linear-gradient(90deg, transparent, #D4AF37, transparent);
    }

    .tent-invitation {
      font-size: 10.2px;
      color: #2F4232;
      max-width: 520px;
      margin: 0 auto 6px auto;
      line-height: 1.38;
      position: relative;
      z-index: 2;
    }

    .tent-invitation strong {
      color: #213424;
    }

    .tent-content-row {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 20px;
      margin-top: 2px;
      position: relative;
      z-index: 2;
    }

    .qr-wrapper {
      display: flex;
      flex-direction: column;
      align-items: center;
    }

    .qr-box {
      width: 122px;
      height: 122px;
      background: linear-gradient(135deg, #4B6651, #D4AF37, #E598A8, #D4AF37);
      padding: 5px;
      border-radius: 16px;
      border: 1.5px solid #B88B1D;
      flex-shrink: 0;
    }

    .qr-ribbon {
      margin-top: -9px;
      background: linear-gradient(90deg, #CF7B8D, #B53F59, #CF7B8D);
      color: #FFFFFF;
      font-size: 8.5px;
      font-weight: 700;
      letter-spacing: 0.8px;
      padding: 2px 12px;
      border-radius: 12px;
      border: 1.5px solid #F7E4A3;
    }

    .steps-card {
      background: #EDF5EE;
      border: 1.5px solid #A8C4AD;
      border-left: 4px solid #D4AF37;
      border-radius: 14px;
      padding: 8px 13px;
      text-align: left;
      font-size: 10.5px;
      color: #263829;
      line-height: 1.38;
    }

    .step-item {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-bottom: 4px;
    }

    .step-badge {
      width: 19px;
      height: 19px;
      font-weight: 800;
      font-size: 10px;
      border-radius: 50%;
      color: #FFFFFF;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      border: 1.2px solid #FFF4D2;
    }
    .step-sage { background: linear-gradient(135deg, #6E8B74, #4B6651); }
    .step-pink { background: linear-gradient(135deg, #E598A8, #B53F59); }
    .step-gold { background: linear-gradient(135deg, #F3DE97, #B88B1D); color: #243527; }

    .no-app-pill {
      margin-top: 3px;
      display: inline-block;
      background: #FFF6F8;
      border: 1px solid #E598A8;
      color: #A63B54;
      font-weight: 700;
      font-size: 9px;
      padding: 2px 10px;
      border-radius: 10px;
    }

    .tent-footer {
      margin-top: 6px;
      padding: 5px 46px 1px 46px;
      border-top: 1.5px solid #D4AF37;
      font-size: 9.5px;
      color: #3D5241;
      display: flex;
      justify-content: space-between;
      align-items: center;
      position: relative;
      z-index: 2;
    }

    .tent-footer .quote {
      font-style: italic;
      color: #B43D59;
      font-weight: 700;
    }

    .tent-footer .key-pill {
      background: linear-gradient(135deg, #4B6651, #38503D);
      border: 1.5px solid #E8C96B;
      padding: 2px 11px;
      border-radius: 14px;
      color: #FFF7D6;
      font-weight: 700;
    }

    /* Doblez central */
    .fold-line-divider {
      margin: 6px 0;
      text-align: center;
      position: relative;
    }

    .fold-line-bar {
      border-top: 2.5px dashed #D4AF37;
      position: relative;
      top: 10px;
    }

    .fold-badge {
      background: linear-gradient(90deg, #4B6651, #C2687C, #D4AF37);
      border: 1.5px solid #FFF2BF;
      color: #FFFFFF;
      font-size: 9.5px;
      font-weight: 700;
      padding: 2.5px 15px;
      border-radius: 14px;
      display: inline-block;
      position: relative;
      z-index: 2;
      letter-spacing: 0.5px;
    }

    .tip-box {
      margin-top: 5px;
      padding: 4px 10px;
      background: linear-gradient(135deg, #EAF3EB 0%, #FDEEF2 100%);
      border: 1px dashed #6E8B74;
      border-radius: 10px;
      text-align: center;
      font-size: 9px;
      color: #3A4D3E;
    }

    /* ======================================================== */
    /* MODELO 2: MINI-TARJETITAS INDIVIDUALES (4 POR PÁGINA)    */
    /* ======================================================== */
    .mini-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .mini-cut-cell {
      border: 1.5px dashed #7D9B83;
      border-radius: 22px;
      padding: 6px;
      background: #F6FAF7;
    }

    .mini-sage-frame {
      background: linear-gradient(145deg, #4B6651 0%, #6E8B74 52%, #47624D 100%);
      padding: 8px;
      border-radius: 18px;
      border: 2px solid #D4AF37;
    }

    .mini-card {
      border: 1.8px solid #E8C96B;
      border-radius: 13px;
      padding: 15px 12px;
      text-align: center;
      background:
        radial-gradient(circle at top right, rgba(229, 152, 168, 0.30) 0%, transparent 45%),
        radial-gradient(circle at bottom left, rgba(110, 139, 116, 0.25) 0%, transparent 45%),
        linear-gradient(180deg, #E2EFE4 0%, #FAFDFB 48%, #FCEAEF 100%);
      position: relative;
      overflow: hidden;
    }

    .mini-card .floral-corner {
      width: 48px;
      height: 48px;
    }

    .mini-top-pill {
      display: inline-block;
      background: linear-gradient(90deg, #4B6651, #C59B27, #C25E75);
      color: white;
      font-size: 8.8px;
      font-weight: 700;
      letter-spacing: 1px;
      padding: 2.5px 14px;
      border-radius: 12px;
      border: 1px solid #FBE9A6;
      margin-bottom: 5px;
      position: relative;
      z-index: 2;
    }

    .mini-crown-wrap {
      display: flex;
      justify-content: center;
      align-items: center;
      width: 36px;
      height: 36px;
      margin: 0 auto 4px auto;
      background: linear-gradient(135deg, #FFF5D1, #F4DA84, #D4AF37);
      border-radius: 50%;
      border: 1.5px solid #FFFFFF;
      outline: 1.2px solid #D4AF37;
      position: relative;
      z-index: 2;
    }

    .mini-title {
      font-family: 'Playfair Display', serif;
      font-size: 19px;
      font-weight: 800;
      color: #B43D59;
      line-height: 1.2;
      position: relative;
      z-index: 2;
    }

    .mini-divider {
      display: flex;
      justify-content: center;
      margin: 3px 0 5px 0;
      position: relative;
      z-index: 2;
    }

    .mini-text {
      font-size: 10px;
      color: #2F4232;
      margin-bottom: 8px;
      line-height: 1.38;
      position: relative;
      z-index: 2;
    }

    .mini-qr-bezel {
      display: inline-block;
      background: linear-gradient(135deg, #4B6651, #D4AF37, #E598A8, #D4AF37);
      padding: 4.5px;
      border-radius: 16px;
      border: 1.2px solid #B88B1D;
      margin-bottom: 8px;
      position: relative;
      z-index: 2;
    }

    .mini-qr {
      width: 130px;
      height: 130px;
      background: white;
      padding: 4px;
      border-radius: 12px;
    }

    .mini-steps {
      font-size: 9.5px;
      color: #2A422F;
      font-weight: 700;
      background: #EDF5EE;
      border: 1px solid #A8C4AD;
      border-radius: 10px;
      padding: 3px 8px;
      display: inline-block;
      margin-bottom: 6px;
      position: relative;
      z-index: 2;
    }

    .mini-footer {
      font-size: 9.2px;
      color: #A63B54;
      font-weight: 700;
      border-top: 1.5px solid #D4AF37;
      padding-top: 5px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      position: relative;
      z-index: 2;
    }

    .mini-key {
      background: #4B6651;
      color: #FFF7D6;
      padding: 1px 7px;
      border-radius: 8px;
      border: 1px solid #D4AF37;
      font-size: 8.8px;
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
    <h2>Kit de Gala para Mesas — Mis 15 Años Danna Alejandra</h2>
    <p>Diseño botánico en Verde Salvia principal, Rosado y Dorado metálico. Carpas que se detienen solas y mini-tarjetitas individuales.</p>
    <button onclick="window.print()">Imprimir Kit Completo</button>
  </div>

  <!-- ========================================================= -->
  <!-- HOJA 1: CARPA DE MESA PLEGABLE (SE DETIENE SOLA)          -->
  <!-- ========================================================= -->
  <div class="page-sheet">
    <div class="model-header">
      ✦ MODELO 1: CARPA DE MESA BOTÁNICA (VERDE SALVIA, ROSADO & DORADO) — SE DETIENE SOLA ✦
    </div>

    <div class="tent-card-wrapper">
      <!-- CARA 1 -->
      ${buildTentFace('Los mejores recuerdos son aquellos que compartimos juntos')}

      <!-- LÍNEA DE DOBLADO CENTRAL -->
      <div class="fold-line-divider">
        <div class="fold-line-bar"></div>
        <span class="fold-badge">✂ DOBLAR POR AQUÍ PARA QUE SE DETENGA SOLA EN LA MESA ✂</span>
      </div>

      <!-- CARA 2 -->
      ${buildTentFace('Gracias por celebrar conmigo este día inolvidable')}

      <div class="tip-box">
        <em>Tip de armado: Imprime en cartulina opalina o couché (200g-240g), recorta el marco punteado exterior y dobla por la línea central dorada formando un triángulo. Se sostendrá firme en cada mesa.</em>
      </div>
    </div>
  </div>

  <!-- ========================================================= -->
  <!-- HOJA 2: TARJETITAS INDIVIDUALES DE MESA (4 POR HOJA)      -->
  <!-- ========================================================= -->
  <div class="page-sheet page-sheet-last">
    <div class="model-header">
      ✦ MODELO 2: TARJETITAS INDIVIDUALES DE GALA (4 POR HOJA PARA PLATO, SERVILLETA O CENTRO) ✦
    </div>

    <div class="mini-grid">
      $miniCardHtml
      $miniCardHtml
      $miniCardHtml
      $miniCardHtml
    </div>
  </div>

</body>
</html>
''';

  // Guardar archivos HTML y mantener sincronizados todos los nombres existentes en web/
  File('tarjeta_mesa_qr.html').writeAsStringSync(html);
  File('web/tarjeta_mesa_qr.html').writeAsStringSync(html);
  File('web/tarjetas_mesa_danna15.html').writeAsStringSync(html);
  print('HTML generado exitosamente en tarjeta_mesa_qr.html, web/tarjeta_mesa_qr.html y web/tarjetas_mesa_danna15.html');

  // Generar PDF usando Chrome headless
  const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  if (File(chromePath).existsSync()) {
    try {
      final outFile = File('web/tarjeta_mesa_qr.pdf');
      if (outFile.existsSync()) {
        outFile.deleteSync();
      }
      final inputUri = Uri.file(File('tarjeta_mesa_qr.html').absolute.path).toString();
      print('Generando PDF de gala con Chrome headless...');
      final result = Process.runSync(
        chromePath,
        [
          '--headless',
          '--disable-gpu',
          '--no-pdf-header-footer',
          '--print-to-pdf=${outFile.absolute.path}',
          inputUri,
        ],
      );
      if (result.exitCode == 0 && outFile.existsSync() && outFile.lengthSync() > 10000) {
        outFile.copySync('tarjeta_mesa_qr.pdf');
        outFile.copySync('web/panfletos_mesa_danna15.pdf');
        print('🎉 ¡PDF generado con éxito (${outFile.lengthSync()} bytes) en web/tarjeta_mesa_qr.pdf, tarjeta_mesa_qr.pdf y web/panfletos_mesa_danna15.pdf!');
      } else {
        print('❌ Falló la generación de PDF en Chrome exit=${result.exitCode}: ${result.stderr}');
        exitCode = 1;
      }
    } catch (e) {
      print('❌ Excepción ejecutando Chrome: $e');
      exitCode = 1;
    }
  }
}
