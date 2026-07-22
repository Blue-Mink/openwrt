#!/bin/sh
# Docker OpenWrt ARM 一键部署脚本
# 在 armv7 宿主机上执行

set -e

# 配置
CONTAINER_IP="192.168.3.A"
HOST_IFACE_IP="192.168.3.B"
NETWORK_NAME="macnet"
IMAGE="sulinggg/openwrt:arm_cortex-a7_neon-vfpv4"
CONTAINER_NAME="openwrt"

echo "=== Docker OpenWrt 部署脚本 ==="
echo "容器IP: ${CONTAINER_IP}"
echo "宿主机虚拟接口IP: ${HOST_IFACE_IP}"
echo "================================"

# 1. 拉取镜像
echo "[1/6] 拉取镜像..."
docker pull "$IMAGE"

# 2. 创建 macvlan 网络
echo "[2/6] 创建 macvlan 网络..."
docker network create -d macvlan \
  --subnet=192.168.3.0/24 \
  --gateway=192.168.3.1 \
  -o parent=eth0 \
  "$NETWORK_NAME" 2>/dev/null || echo "网络已存在，跳过"

# 3. 停止并删除旧容器
echo "[3/6] 清理旧容器..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# 4. 启动容器
echo "[4/6] 启动容器..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --network "$NETWORK_NAME" \
  --ip "$CONTAINER_IP" \
  --privileged \
  "$IMAGE"

# 5. 配置宿主机互通
echo "[5/6] 配置宿主机与容器互通..."
ip link add macvlan-host link eth0 type macvlan mode bridge 2>/dev/null || ip link del macvlan-host && ip link add macvlan-host link eth0 type macvlan mode bridge
ip addr add "${HOST_IFACE_IP}/24" dev macvlan-host 2>/dev/null || true
ip link set macvlan-host up
ip route add "${CONTAINER_IP}/32" dev macvlan-host 2>/dev/null || true

# 6. 验证
echo "[6/6] 验证部署..."
sleep 3
echo "--- 容器状态 ---"
docker ps --filter name="$CONTAINER_NAME" --format "{{.Names}}  {{.Status}}"
echo "--- 连通性测试 ---"
if ping -c 2 "$CONTAINER_IP" >/dev/null 2>&1; then
  echo "✅ 宿主机 → 容器: 通"
else
  echo "⚠️  宿主机 → 容器: 不通（检查 macvlan-host 接口）"
fi
echo "=== 部署完成 ==="
echo "Luci 地址: http://${CONTAINER_IP}"
echo "用户名: root  密码: admin"
