# cr-nginx

Official patched Nginx runtime with minimal `ngx_http_lua` support.

## Quick Start

### Init Development Environment

```shell
pre-commit install
```

### List Available Tasks

```shell
task -a
```

### Build Container

```shell
task container:build:local
```

The local build task loads `cr-nginx:latest` into Docker and never pushes it.

### Run Container

```shell
docker run --rm -p 8080:80 cr-nginx:latest
```

The image provides Lua inside Nginx through `ngx_http_lua`. It does not install a standalone Lua CLI or optional Redis, Kafka, Memcached, DNS, and WebSocket Lua clients.

Multi-platform images are published to GHCR only when a `v*` tag is pushed.

## Related Links

- [Nginx](https://nginx.org/)
- [lua-nginx-module](https://github.com/openresty/lua-nginx-module)
- [Taskfile](https://taskfile.dev/)
- [Pre-commit](https://pre-commit.com/)
