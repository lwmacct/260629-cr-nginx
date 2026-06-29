# syntax=docker/dockerfile:1
# https://hub.docker.com/_/ubuntu
FROM ubuntu:resolute-20260421
LABEL maintainer="https://github.com/lwmacct"
LABEL org.opencontainers.image.source="https://github.com/lwmacct/260629-cr-nginx"
ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

RUN <<'RUN_EOF'
set -eux
echo "配置源, 容器内源文件为 /etc/apt/sources.list.d/ubuntu.sources"
sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's@//ports.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/ubuntu.sources
apt-get update
apt-get install -y --no-install-recommends tini ca-certificates curl wget sudo pcp gnupg
sed -i 's@http:@https:@g' /etc/apt/sources.list.d/ubuntu.sources
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "设置 PS1"
cat >> /root/.bashrc <<"EOF"
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u\[\033[00m\]@\[\033[01;35m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
RUN_EOF

RUN <<'RUN_EOF'
set -eux
echo "语言/时间"
apt-get update
apt-get install -y --no-install-recommends locales tzdata
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone
apt-get clean
rm -rf /var/lib/apt/lists/*
echo
RUN_EOF

RUN <<'RUN_EOF'
set -eux
echo "安装 nginx 和 lua 模块"
apt-get update
apt-get install -y --no-install-recommends nginx libnginx-mod-http-lua 'lua-nginx-*'
nginx -V
apt-get clean
rm -rf /var/lib/apt/lists/*
RUN_EOF

EXPOSE 80
STOPSIGNAL SIGQUIT
ENTRYPOINT ["tini", "--"]
CMD ["nginx", "-g", "daemon off;"]
