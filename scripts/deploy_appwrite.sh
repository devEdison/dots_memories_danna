#!/usr/bin/env bash
set -e

echo "🌸 Compilando Flutter Web para Appwrite..."
flutter build web --release --base-href "/"

echo "🚀 Desplegando en Appwrite Sites (dots-memories-danna)..."
appwrite sites create-deployment --site-id dots-memories-danna --code build/web --activate

echo ""
echo "✨ ¡Despliegue completado con éxito en Appwrite!"
echo "🌐 URL pública: https://danna15-memories.appwrite.network"
echo "🔑 URL con llave QR: https://danna15-memories.appwrite.network/?key=DANNA15"
