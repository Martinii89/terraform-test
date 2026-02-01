services:

  certbot-init:
    image: certbot/dns-cloudflare
    container_name: certbot-init
    volumes:
      - certs:/etc/letsencrypt
      - ./certbot/cloudflare.ini:/etc/cloudflare.ini:ro
    command: certonly --dns-cloudflare --dns-cloudflare-credentials /etc/cloudflare.ini -d ${DOMAIN_NAME} --agree-tos -n -m ${LETSENCRYPT_EMAIL} --post-hook "chmod -R 755 /etc/letsencrypt/live && chmod -R 755 /etc/letsencrypt/archive"

  nginx:
    image: ghcr.io/nginxinc/nginx-unprivileged:stable
    container_name: nginx
    restart: unless-stopped
    ports:
      - "443:443/tcp"
      - "443:443/udp"   # HTTP/3
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/sites:/etc/nginx/conf.d:ro
      - certs:/etc/letsencrypt:ro
    depends_on:
      certbot-init:
        condition: service_completed_successfully
        required: true

  api:
    image: mendhak/http-https-echo:39
    container_name: api
    environment:
    - HTTP_PORT=3000
    expose:
      - "3000"

volumes:
  certs:
