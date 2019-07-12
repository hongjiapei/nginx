FROM alpine:3.9

ENV TZ CST-8
ENV EXEC_USER www-data
ENV NGINX_VERSION 1.16.0
ENV NGINX_DIR /usr/local/nginx

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
        && apk add --no-cache --virtual .persistent-deps ca-certificates curl pcre libzip zlib freetype libpng jpeg libcrypto1.1 libssl1.1 libressl libstdc++ gettext-dev gettext bison \
        && set -xe \
        && addgroup -g 82 -S $EXEC_USER \
        && adduser -u 82 -D -S -G $EXEC_USER $EXEC_USER \
        && mkdir -p /usr/src && mkdir -p /usr/local/sbin \
        \
        \
        \
#开始安装nginx
        && export CFLAGS="-pipe -O -W -Wall -Wpointer-arith -Wno-unused-parameter -Werror" \
        && apk add --no-cache --virtual .nginx-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers gnupg libxslt-dev gd-dev geoip-dev \
        && cd /usr/src && wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz && tar -xvf nginx-$NGINX_VERSION.tar.gz && rm nginx-$NGINX_VERSION.tar.gz && mv nginx-$NGINX_VERSION nginx \
        && cd /usr/src/nginx \
        && mkdir -p $NGINX_DIR/conf.d && mkdir -p $NGINX_DIR/logs && chown -R $EXEC_USER.$EXEC_USER $NGINX_DIR/logs && mkdir -p $NGINX_DIR/run && chown -R $EXEC_USER.$EXEC_USER $NGINX_DIR/run \
        && ./configure \
                --prefix=$NGINX_DIR \
                --conf-path=$NGINX_DIR/conf/nginx.conf \
                --modules-path=$NGINX_DIR/modules \
                --user=$EXEC_USER \
                --group=$EXEC_USER \
                --with-http_ssl_module \
                --with-http_v2_module \
                --with-http_realip_module \
                --with-http_geoip_module=dynamic \
                --with-http_gunzip_module \
                --with-http_gzip_static_module \
#               --with-http_addition_module \
#               --with-http_sub_module \
#               --with-http_dav_module \
#               --with-http_flv_module \
#               --with-http_mp4_module \
#               --with-http_random_index_module \
#               --with-http_secure_link_module \
#               --with-http_stub_status_module \
#               --with-http_auth_request_module \
#               --with-http_xslt_module=dynamic \
#               --with-http_image_filter_module=dynamic \
#               --with-threads \
#               --with-stream \
#               --with-stream_ssl_module \
#               --with-stream_ssl_preread_module \
#               --with-stream_realip_module \
#               --with-stream_geoip_module=dynamic \
#               --with-http_slice_module \
#               --with-mail \
#               --with-mail_ssl_module \
#               --with-compat \
#               --with-file-aio \
                \
        && make -j$(getconf _NPROCESSORS_ONLN) \
        && make install && make clean \
        && { \
                echo -e ""; \
                echo -e "user $EXEC_USER;"; \
                echo -e "worker_processes  1;\n\n"; \
                echo -e "error_log  $NGINX_DIR/logs/error.log warn;"; \
                echo -e "pid  $NGINX_DIR/run/nginx.pid;\n\n"; \
                echo -e "events {"; \
                echo -e "       worker_connections  1024;"; \
                echo -e "}\n\n"; \
                echo -e "http {"; \
                echo -e "       include       $NGINX_DIR/conf/mime.types;"; \
                echo -e "       default_type  application/octet-stream;\n\n"; \
                echo -e "       log_format  main  '\$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status $body_bytes_sent \"\$http_referer\" \"\$http_user_agent\" \"\$http_x_forwarded_for\"'"; \
                echo -e "       access_log  $NGINX_DIR/logs/access.log  main;\n\n"; \
                echo -e "       sendfile        on;"; \
                echo -e "       keepalive_timeout  65;\n\n"; \
                echo -e "       include $NGINX_DIR/conf.d/*.conf;"; \
                echo -e "}\n\n"; \
        } | tee $NGINX_DIR/conf/nginx.conf \
        && export -n CFLAGS \
        && cd / && apk del .nginx-deps && rm -rf /usr/src/nginx \
        \
        && ln -s $NGINX_DIR/sbin/nginx /usr/local/sbin/nginx
