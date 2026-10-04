#!/bin/bash
set -e

echo "=== PlayNed Frontend: Vercel Build Step ==="

# Clone Flutter stable if not present in cache
if [ ! -d "$HOME/flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"
flutter config --no-analytics
flutter --version

echo "Fetching dependencies..."
flutter pub get

echo "Building Flutter Web release..."
if [ -n "$API_URL" ]; then
  echo "Injecting API_URL: $API_URL"
  flutter build web --release --dart-define=API_URL="$API_URL" --dart-define=WS_URL="$WS_URL"
else
  flutter build web --release
fi

echo "Copying vercel.json into build/web..."
cp vercel.json build/web/vercel.json || true

echo "=== Build Complete ==="
