# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION="resolute-20260421"

FROM ubuntu:${UBUNTU_VERSION}

LABEL maintainer="https://github.com/lwmacct"
LABEL org.opencontainers.image.source="https://github.com/lwmacct/260629-cr-nginx"
LABEL org.opencontainers.image.description="Ubuntu Nginx runtime with minimal ngx_http_lua support"
LABEL org.opencontainers.image.licenses="MIT"

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    TZ="Asia/Shanghai"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      iproute2 \
      libnginx-mod-http-lua \
      nginx \
      tini \
      tzdata; \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    printf '%s\n' 'Asia/Shanghai' >/etc/timezone; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    _config_file="$(mktemp)"; \
    printf '%s\n' \
      'include /etc/nginx/modules-enabled/*.conf;' \
      'error_log stderr notice;' \
      'pid /tmp/nginx.pid;' \
      'events {}' \
      'http {' \
      '  init_by_lua_block {' \
      '    assert(ngx.config.ngx_lua_version)' \
      '    require "resty.core"' \
      '    require "resty.lrucache"' \
      '  }' \
      '  server {' \
      '    listen 18080;' \
      '    location = /lua-health {' \
      '      content_by_lua_block { ngx.say("lua-ok") }' \
      '    }' \
      '  }' \
      '}' \
      >"$_config_file"; \
    nginx -t -c "$_config_file"; \
    timeout --preserve-status --signal=QUIT 1 \
      nginx -c "$_config_file" -g 'daemon off;'; \
    rm -f "$_config_file"; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80
STOPSIGNAL SIGQUIT
ENTRYPOINT ["tini", "-g", "--"]
CMD ["nginx", "-g", "daemon off;"]
