#!/bin/sh
# Docker OpenWrt 镜像导出脚本
# 在有 Docker 并能拉取 ARM 镜像的环境上执行

set -e

IMAGE="sulinggg/openwrt:arm_cortex-a7_neon-vfpv4"
OUTPUT="openwrt-armv7.tar.gz"

echo "=== 拉取最新镜像 ==="
docker pull "$IMAGE"

echo "=== 导出镜像 ==="
echo "正在导出 $IMAGE -> ${OUTPUT%.gz} ..."
docker save "$IMAGE" -o "${OUTPUT%.gz}"

echo "=== 压缩 ==="
gzip -f "${OUTPUT%.gz}"

echo "=== 完成 ==="
ls -lh "$OUTPUT"
echo "将此文件上传到目标设备后执行: gunzip -c $OUTPUT | docker load"
