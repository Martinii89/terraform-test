#!/bin/bash
set -e

# Update system packages
apt-get update
apt-get upgrade -y

# Install web server
apt-get install -y nginx

# Create a simple hello world page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            text-align: center;
            background: white;
            padding: 50px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
        }
        h1 {
            color: #333;
            margin: 0 0 20px 0;
        }
        p {
            color: #666;
            font-size: 18px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello World! 👋</h1>
        <p>Your web server is running successfully</p>
    </div>
</body>
</html>
EOF

# Create a simple health check endpoint
cat > /var/www/html/health.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>Server is healthy</h1>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Configure Nginx to handle HTTP to HTTPS redirect
cat > /etc/nginx/sites-available/default <<'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name _;

    # SSL configuration (managed by load balancer, but needed for direct access)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_EOF

# Test Nginx configuration
nginx -t

# Enable and start nginx
systemctl enable nginx
systemctl start nginx
systemctl restart nginx

echo "Droplet initialization complete"
