#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., sudo biosite logs)"
  exit 1
fi

case "$1" in
    start)
        systemctl start nginx
        echo "Biosite (Nginx) started."
        ;;
    stop)
        systemctl stop nginx
        echo "Biosite (Nginx) stopped."
        ;;
    restart)
        systemctl restart nginx
        echo "Biosite (Nginx) restarted."
        ;;
    status)
        systemctl status nginx
        ;;
    logs)
        tail -f /var/log/nginx/access.log -f /var/log/nginx/error.log
        ;;
    ssl)
        echo "--- Manual Let's Encrypt SSL Configuration ---"
        read -p "Enter the domain name (e.g., example.com): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            echo "Error: Domain name is required."
            exit 1
        fi
        read -p "Enter email for Let's Encrypt renewal notices (optional): " EMAIL

        if [ -n "$EMAIL" ]; then
            certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
        else
            certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
        fi
        systemctl restart nginx
        echo "SSL Certificate configured successfully."
        ;;
    *)
        echo "Usage: biosite {start|stop|restart|status|logs|ssl}"
        exit 1
        ;;
esac
