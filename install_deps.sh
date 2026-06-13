#!/bin/bash

set -e

echo "=== Проверка окружения ==="

if ! command -v npm &> /dev/null; then
    echo "Failure: Node.js and NPM are not installed."
    exit 1
fi

echo "=== Установка зависимостей Astro и Tailwind ==="
npm install astro @astrojs/tailwind tailwindcss --legacy-peer-deps

echo "========================================================="
echo " Dependencies are successfully installed!"
echo "========================================================="
