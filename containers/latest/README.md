# latest container

This directory maintains the `latest` patched official Nginx image.

## Runtime

- Official `nginx:1.31.9` image
- Dynamic modules built against the exact official Nginx build:
  Lua/NDK, headers-more, echo, and Brotli
- Third-party module versions resolved from the newest upstream Git tag at
  build time, including a pre-release tag when it is the newest one
- Exact source commit IDs in `/usr/share/doc/cr-nginx/module-versions.txt`
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

## Module versions

Third-party module versions accept three values:

- `latest`: the newest upstream Git tag, including a pre-release tag when it is newest.
- `stable`: the newest upstream Git tag excluding `rc`, `alpha`, `beta`, and `dev`.
- An explicit version such as `1.0.0rc` or `v1.0.0rc`.

The local task and CI pass a changing `MODULE_CACHE_BUST` build argument so cached builds do not reuse an earlier `latest` lookup. Resolved versions and immutable source commit IDs are printed during the build and stored in `/usr/share/doc/cr-nginx/module-versions.txt`.
