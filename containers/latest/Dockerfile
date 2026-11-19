# syntax=docker/dockerfile:1

# Build dynamic modules against the exact nginx build in the runtime image.
FROM nginx:1.31.9 AS module-builder

ARG DEBIAN_FRONTEND="noninteractive"

WORKDIR /usr/src

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      libbrotli-dev \
      libluajit-5.1-dev \
      libpcre2-dev \
      libssl-dev \
      zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*

ARG NGINX_VERSION="1.31.9"
ARG NGX_DEVEL_KIT_VERSION="latest"
ARG LUA_NGINX_MODULE_VERSION="latest"
ARG HEADERS_MORE_VERSION="latest"
ARG ECHO_VERSION="latest"
ARG NGX_BROTLI_VERSION="latest"
ARG LUA_RESTY_CORE_VERSION="latest"
ARG LUA_RESTY_LRUCACHE_VERSION="latest"
ARG MODULE_CACHE_BUST="manual"

RUN <<'EOF'
set -eux

# Reference the cache key explicitly so a changing MODULE_CACHE_BUST forces a
# fresh tag lookup instead of reusing Docker's cached "latest" resolution.
printf '%s\n' "$MODULE_CACHE_BUST"

__resolve_tag() {
  _resolve_repo="$1"
  _resolve_requested="$2"

  if [ "$_resolve_requested" = "latest" ] || [ "$_resolve_requested" = "stable" ]; then
    _resolve_line="$(
      git ls-remote --tags --sort='-v:refname' \
        "https://github.com/${_resolve_repo}.git" 'refs/tags/v*' \
        | sed -n 's#^\([0-9a-f][0-9a-f]*\)[[:space:]][[:space:]]*refs/tags/\([^{}][^{}]*\)$#\1 \2#p' \
        | if [ "$_resolve_requested" = "stable" ]; then
            grep -Eiv '(rc|alpha|beta|dev)'
          else
            cat
          fi \
        | head -n 1
    )"
    test -n "$_resolve_line"
    set -- $_resolve_line
    _resolve_tag="$2"
  else
    case "$_resolve_requested" in
      v*) _resolve_tag="$_resolve_requested" ;;
      *) _resolve_tag="v$_resolve_requested" ;;
    esac
  fi

  test -n "$_resolve_tag"
}

__tag_commit() {
  _commit_repo="$1"
  _commit_tag="$2"
  _commit_value="$(
    git ls-remote "https://github.com/${_commit_repo}.git" \
      "refs/tags/${_commit_tag}^{}" \
      | sed -n 's#^\([0-9a-f][0-9a-f]*\).*$#\1#p' \
      | head -n 1
  )"

  if [ -z "$_commit_value" ]; then
    _commit_value="$(
      git ls-remote "https://github.com/${_commit_repo}.git" \
        "refs/tags/${_commit_tag}" \
        | sed -n 's#^\([0-9a-f][0-9a-f]*\).*$#\1#p' \
        | head -n 1
    )"
  fi

  test -n "$_commit_value"
  printf '%s\n' "$_commit_value"
}

__fetch_module() {
  _module_repo="$1"
  _module_key="$2"
  _module_name="$3"
  _module_requested="$4"

  __resolve_tag "$_module_repo" "$_module_requested"
  _module_tag="$_resolve_tag"
  _module_version="${_module_tag#v}"
  _module_commit="$(__tag_commit "$_module_repo" "$_module_tag")"
  _module_archive="${_module_name}-${_module_commit}.tar.gz"

  curl -fsSL \
    "https://github.com/${_module_repo}/archive/${_module_commit}.tar.gz" \
    -o "$_module_archive"
  tar -xzf "$_module_archive"

  _module_source_dir="$(
    tar -tzf "$_module_archive" \
      | head -n 1 \
      | sed 's#^/##; s#/$##'
  )"
  test -n "$_module_source_dir"
  mv "$_module_source_dir" "${_module_name}-source"

  printf '%s=%s\n' "$_module_key" "$_module_version" \
    >>/usr/src/module-versions.txt
  printf '%s_commit=%s\n' "$_module_key" "$_module_commit" \
    >>/usr/src/module-versions.txt
}

{
  printf '%s=%s\n' nginx "$NGINX_VERSION"
  printf 'nginx_channel=pinned\n'
} >/usr/src/module-versions.txt

curl -fsSLO "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"
tar -xzf "nginx-${NGINX_VERSION}.tar.gz"

__fetch_module vision5/ngx_devel_kit ngx_devel_kit ngx_devel_kit \
  "$NGX_DEVEL_KIT_VERSION"
__fetch_module openresty/lua-nginx-module lua_nginx_module lua-nginx-module \
  "$LUA_NGINX_MODULE_VERSION"
__fetch_module openresty/headers-more-nginx-module headers_more headers-more-nginx-module \
  "$HEADERS_MORE_VERSION"
__fetch_module openresty/echo-nginx-module echo echo-nginx-module \
  "$ECHO_VERSION"
__fetch_module google/ngx_brotli ngx_brotli ngx_brotli \
  "$NGX_BROTLI_VERSION"
__fetch_module openresty/lua-resty-core lua_resty_core lua-resty-core \
  "$LUA_RESTY_CORE_VERSION"
__fetch_module openresty/lua-resty-lrucache lua_resty_lrucache lua-resty-lrucache \
  "$LUA_RESTY_LRUCACHE_VERSION"
EOF

RUN set -eux; \
    cd "nginx-${NGINX_VERSION}"; \
    _lua_module_api_version="$(sed -n 's/^#define ngx_http_lua_version[[:space:]]*\([0-9][0-9]*\).*/\1/p' /usr/src/lua-nginx-module-source/src/api/ngx_http_lua_api.h)"; \
    _lua_core_required_version="$(grep -m1 -E 'ngx[.]config[.]ngx_lua_version[[:space:]]*~=' /usr/src/lua-resty-core-source/lib/resty/core/base.lua | sed -n 's/.*ngx_lua_version[[:space:]]*~=[[:space:]]*\([0-9][0-9]*\).*/\1/p')"; \
    test -n "$_lua_module_api_version"; \
    test -n "$_lua_core_required_version"; \
    test "$_lua_module_api_version" = "$_lua_core_required_version"; \
    _configure_args="$(nginx -V 2>&1 | sed -n 's/^configure arguments: //p')"; \
    LUAJIT_INC="/usr/include/luajit-2.1"; \
    LUAJIT_LIB="/usr/lib/$(gcc -print-multiarch)"; \
    export LUAJIT_INC LUAJIT_LIB; \
    eval "set -- ${_configure_args}"; \
    ./configure "$@" \
      --add-dynamic-module=/usr/src/ngx_devel_kit-source \
      --add-dynamic-module=/usr/src/lua-nginx-module-source \
      --add-dynamic-module=/usr/src/headers-more-nginx-module-source \
      --add-dynamic-module=/usr/src/echo-nginx-module-source \
      --add-dynamic-module=/usr/src/ngx_brotli-source; \
    make -j"$(nproc)" modules; \
    printf '\nResolved module versions:\n'; \
    cat /usr/src/module-versions.txt

FROM nginx:1.31.9

LABEL maintainer="https://github.com/lwmacct"
LABEL org.opencontainers.image.source="https://github.com/lwmacct/260629-cr-nginx"
LABEL org.opencontainers.image.description="Patched official Nginx runtime with minimal ngx_http_lua support"
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
      libbrotli1 \
      libluajit-5.1-2 \
      tini \
      tzdata; \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    printf '%s\n' 'Asia/Shanghai' >/etc/timezone; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    mkdir -p /etc/nginx/modules-enabled /etc/nginx/sites-enabled; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --from=module-builder /usr/src/nginx-1.31.9/objs/*.so /usr/lib/nginx/modules/
COPY --from=module-builder /usr/src/lua-resty-core-source/lib/resty/ /usr/local/share/lua/5.1/resty/
COPY --from=module-builder /usr/src/lua-resty-lrucache-source/lib/resty/ /usr/local/share/lua/5.1/resty/
COPY --from=module-builder /usr/src/module-versions.txt /usr/share/doc/cr-nginx/module-versions.txt

RUN set -eux; \
    printf '%s\n' 'Installed module versions:'; \
    cat /usr/share/doc/cr-nginx/module-versions.txt; \
    printf '%s\n' \
      'load_module modules/ndk_http_module.so;' \
      'load_module modules/ngx_http_lua_module.so;' \
      'load_module modules/ngx_http_headers_more_filter_module.so;' \
      'load_module modules/ngx_http_echo_module.so;' \
      'load_module modules/ngx_http_brotli_filter_module.so;' \
      'load_module modules/ngx_http_brotli_static_module.so;' \
      >/etc/nginx/modules-enabled/10-project-modules.conf; \
    printf '%s\n' \
      'include /etc/nginx/modules-enabled/*.conf;' \
      'worker_processes auto;' \
      'error_log /var/log/nginx/error.log notice;' \
      'pid /run/nginx.pid;' \
      'events {' \
      '  worker_connections 1024;' \
      '}' \
      'http {' \
      '  include /etc/nginx/mime.types;' \
      '  default_type application/octet-stream;' \
      '  sendfile on;' \
      '  keepalive_timeout 65;' \
      '  include /etc/nginx/conf.d/*.conf;' \
      '  include /etc/nginx/sites-enabled/*;' \
      '}' \
      >/etc/nginx/nginx.conf; \
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
    rm -f "$_config_file"

EXPOSE 80
STOPSIGNAL SIGQUIT
ENTRYPOINT ["tini", "-g", "--"]
CMD ["nginx", "-g", "daemon off;"]
