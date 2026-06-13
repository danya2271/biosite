#!/bin/bash

# 1. Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./biosite-installer.sh)"
  exit 1
fi

# 2. Extract the embedded archive payload
echo "Extracting installer payload..."
TEMP_DIR=$(mktemp -d)

PAYLOAD_LINE=$(awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' "$0")

if ! tail -n +$PAYLOAD_LINE "$0" | tar -xz -C "$TEMP_DIR" 2>/dev/null; then
    echo "Error: Failed to extract payload. The installer file might be corrupted."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 3. Configure Domain and Email
echo "--- Biosite Installer ---"

RECONFIGURE_SSL="yes"
DOMAIN=""

if [ -f /etc/nginx/sites-available/biosite ]; then
    EXISTING_DOMAIN=$(grep -oP 'server_name\s+\K[^;\s]+' /etc/nginx/sites-available/biosite | head -n 1)
    if [ -n "$EXISTING_DOMAIN" ]; then
        echo "Found existing domain configuration: '$EXISTING_DOMAIN'"
        read -p "Do you want to reconfigure the domain and SSL? [y/N] (default: n): " RECONF
        if [[ "$RECONF" =~ ^[Yy]$ ]]; then
            RECONFIGURE_SSL="yes"
        else
            RECONFIGURE_SSL="no"
            DOMAIN=$EXISTING_DOMAIN
        fi
    fi
fi

if [ "$RECONFIGURE_SSL" = "yes" ]; then
    read -p "Enter the domain name for this website (e.g., example.com): " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo "Error: Domain name is required."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    read -p "Enter email for Let's Encrypt SSL renewal notices (optional but recommended): " EMAIL
fi

read -p "Enter email for Let's Encrypt SSL renewal notices (optional but recommended): " EMAIL

# 4. Install Dependencies (Removed python3)
echo "Installing Nginx and Certbot..."
apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

# 5. Install Website Files (Astro dist folder)
echo "Deploying website files..."
mkdir -p /opt/biosite
# Clean old files if updating
rm -rf /opt/biosite/*
# Copy all contents of dist to /opt/biosite
cp -r "$TEMP_DIR/dist/"* /opt/biosite/
chown -R www-data:www-data /opt/biosite

# 6. Install CLI Tool
echo "Installing 'biosite' CLI tool..."
cp "$TEMP_DIR/biosite.sh" /usr/local/bin/biosite
chmod +x /usr/local/bin/biosite

# 7. Configure Nginx to serve files directly
if [ "$RECONFIGURE_SSL" = "yes" ]; then
    echo "Configuring Nginx reverse proxy..."
    cat <<EOF > /etc/nginx/sites-available/biosite
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root /opt/biosite;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Caching for media (video/audio)
    location ~* \.(mp4|mp3|ogg|webm)$ {
        expires max;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

    # Link config and remove default Nginx page to prevent conflicts
    ln -sf /etc/nginx/sites-available/biosite /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
fi

systemctl reload nginx

# 8. Setup Let's Encrypt SSL
if [ "$RECONFIGURE_SSL" = "yes" ]; then
    echo "Requesting Let's Encrypt SSL Certificate..."
    if [ -n "$EMAIL" ]; then
        certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
    else
        certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
    fi
fi

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "================================================================"
echo " Installation Complete!"
echo " URL: https://$DOMAIN"
echo " You can now manage your site using: biosite"
echo " Example: sudo biosite restart  |  sudo biosite logs"
echo "================================================================"

exit 0
__PAYLOAD_BELOW__
