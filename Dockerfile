FROM alpine:latest

# Install nginx and envsubst
RUN apk add --no-cache nginx gettext

# Create an advanced Nginx config handling all Signal subdomains
RUN echo 'events { worker_connections 1024; } \
http { \
    # Optimize for large file transfers (Signal attachments) \
    client_max_body_size 100M; \
    proxy_read_timeout 3600s; \
    proxy_send_timeout 3600s; \
    \
    server { \
        listen ${PORT}; \
        \
        # 1. Text Messaging & Core Service \
        location / { \
            proxy_pass https://textsecure-service.whispersystems.org; \
            proxy_ssl_server_name on; \
            proxy_set_header Host textsecure-service.whispersystems.org; \
            proxy_buffering off; \
        } \
        \
        # 2. Attachments and Storage \
        location /storage/ { \
            proxy_pass https://storage.signal.org/; \
            proxy_ssl_server_name on; \
            proxy_set_header Host storage.signal.org; \
        } \
        \
        # 3. Voice and Video Calls \
        location /voip/ { \
            proxy_pass https://sfu.voip.signal.org/; \
            proxy_ssl_server_name on; \
            proxy_set_header Host sfu.voip.signal.org; \
            proxy_buffering off; \
        } \
        \
        # 4. Directory & Discovery \
        location /directory/ { \
            proxy_pass https://api.directory.signal.org/; \
            proxy_ssl_server_name on; \
            proxy_set_header Host api.directory.signal.org; \
        } \
    } \
}' > /etc/nginx/nginx.conf.template

CMD envsubst '$PORT' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'
