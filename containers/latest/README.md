# latest container

This directory maintains the `latest` Ubuntu Nginx image.

## Runtime

- Ubuntu `resolute-20260421`
- Distribution Nginx
- `libnginx-mod-http-lua`
- LuaJIT runtime libraries
- `lua-resty-core` and `lua-resty-lrucache`
- Native `linux/amd64` and `linux/arm64` images

The default process is:

```shell
nginx -g "daemon off;"
```

The process chain is `tini -> Nginx`. Replacing the container command runs the replacement directly under Tini.

## Lua

The image supports embedded Nginx Lua directives such as `init_by_lua_block` and `content_by_lua_block`, including the core `ngx.*` APIs.

It intentionally does not include a standalone `lua` or `luajit` command, or optional `lua-nginx-*` client libraries. Add explicit packages only when an application requires them.

## Configuration

- Main configuration: `/etc/nginx/nginx.conf`
- HTTP snippets: `/etc/nginx/conf.d/*.conf`
- Virtual hosts: `/etc/nginx/sites-enabled/*`
- Access log: `/dev/stdout`
- Error log: `/dev/stderr`

## Build

From the repository root:

```shell
task container:build:local
```

From this directory:

```shell
task build:local
```

Override the local image name when needed:

```shell
task container:build:local IMAGE=cr-nginx:dev
```

The local task uses the host build network and loads a single-platform image into Docker. It never pushes an image. Multi-platform GHCR publishing is owned by the tag-triggered GitHub Actions workflow.
