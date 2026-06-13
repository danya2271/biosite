#!/bin/bash

set -e

echo "Building Astro website..."
if [ ! -d "node_modules" ]; then
    npm install
fi
npm run build

echo "Preparing files for build..."
PAYLOAD_DIR=$(mktemp -d)

cp -r dist "$PAYLOAD_DIR/dist"
cp biosite.sh "$PAYLOAD_DIR/"

tar -czf payload.tar.gz -C "$PAYLOAD_DIR" .

cat install.sh payload.tar.gz > biosite-installer.sh
chmod +x biosite-installer.sh

# Clean up
rm -rf "$PAYLOAD_DIR"
rm -f payload.tar.gz

echo "=============================================="
echo "Package created successfully: biosite-installer.sh"
echo "You can copy this single file to your server"
echo "and run it using: sudo ./biosite-installer.sh"
echo "=============================================="
