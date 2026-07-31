#!/usr/bin/env bash

__main() {

  DOCKER_IMAGE=${DOCKER_IMAGE:-ghcr.io/lwmacct/260629-cr-nginx:latest}

  {
    _proxy="ghcr.nju.edu.cn/"
    _image1="${_proxy}$DOCKER_IMAGE"
    _image2="$(docker images -q "$_image1")"
    if [[ "$_image2" == "" ]]; then docker pull "$_image1" && _image2="$(docker images -q "$_image1")"; fi
  }

  _image_ref="${DOCKER_IMAGE##*/}"
  _image_name="${_image_ref%%:*}"
  _app_name="${CONTAINER_NAME:-${_image_name:-$(basename "${BASH_SOURCE[0]}" .sh)}}"
  _app_data="/data/$_app_name"
  cat <<EOF | docker compose -p "$_app_name" -f - up -d --remove-orphans
services:
  main:
    container_name: $_app_name
    image: "$_image2"
    restart: always
    network_mode: host
    volumes:
      - /data/deploy:/data/deploy
    environment:
      - TZ=Asia/Shanghai
EOF
}

__help() {
  cat <<EOF

EOF
}

__main
