FROM alpine:latest

# Install nginx and envsubst
RUN apk add --no-cache nginx gettext

# Create an advanced Nginx config handling all Signal subdomains dynamically
RUN echo 'events { worker_connections 1024; } \
http { \
    client_max_body_size 100M; \
    proxy_read_timeout 3600s; \
    proxy_send_timeout 3600s; \
    \
    # Use Cloudflare and Google DNS to resolve domains dynamically \
    resolver 1.1.1.1 8.8.8.8 valid=300s; \
    resolver_timeout 5s; \
    \
    server { \
        listen ${PORT}; \
        \
        # 1. Text Messaging & Core Service \
        location / { \
            set $backend "https://textsecure-service.whispersystems.org"; \
            proxy_pass $backend; \
            proxy_ssl_server_name on; \
            proxy_set_header Host textsecure-service.whispersystems.org; \
            proxy_buffering off; \
        } \
        \
        # 2. Attachments and Storage \
        location /storage/ { \
            set $backend "https://storage.signal.org/"; \
            proxy_pass $backend; \
            proxy_ssl_server_name on; \
            proxy_set_header Host storage.signal.org; \
        } \
        \
        # 3. Voice and Video Calls \
        location /voip/ { \
            set $backend "https://sfu.voip.signal.org/"; \
            proxy_pass $backend; \
            proxy_ssl_server_name on; \
            proxy_set_header Host sfu.voip.signal.org; \
            proxy_buffering off; \
        } \
        \
        # 4. Directory & Discovery \
        location /directory/ { \
            set $backend "https://api.directory.signal.org/"; \
            proxy_pass $backend; \
            proxy_ssl_server_name on; \
            proxy_set_header Host api.directory.signal.org; \
        } \
    } \
}' > /etc/nginx/nginx.conf.template

CMD envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'
