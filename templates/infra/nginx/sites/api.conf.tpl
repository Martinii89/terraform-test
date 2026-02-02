{% if useCertbot %}
server {
    listen 443 ssl;
    listen 443 quic reuseport;
    http2 on;
    server_name {{ domainName }};

    ssl_certificate     /etc/letsencrypt/live/{{ domainName }}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{{ domainName }}/privkey.pem;

    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
{% else %}
# Cloudflare origin certificate configuration (HTTP on port 80 for Cloudflare proxy)
server {
    listen 80;
    listen 443 ssl;
    http2 on;
    server_name {{ domainName }};

    # Cloudflare origin certificate (mounted from host)
    ssl_certificate     /etc/nginx/conf.d/origin-cert.pem;
    ssl_certificate_key /etc/nginx/conf.d/origin-key.pem;

    location / {
        proxy_pass http://api:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
{% endif %}
