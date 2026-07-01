# latest container

这个目录维护 `latest` 镜像的 Dockerfile 构建定义。

## 构建

```bash
containers/latest/build.sh ghcr.io/lwmacct/260629-cr-nginx:latest
```

默认构建并推送：

```bash
PLATFORMS=linux/amd64,linux/arm64 containers/latest/build.sh
```

构建上下文必须是仓库根目录，Dockerfile 路径为 `containers/latest/Dockerfile`。
