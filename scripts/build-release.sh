#!/bin/sh
# Release 发布包构建脚本
# 将 Docker 镜像 + 安装说明打包为一个自包含的归档
# 用法: ./scripts/build-release.sh

set -e

RELEASE_DIR="release"
DIST_DIR="dist"
VERSION="${1:-v1.0.0}"
ARCHIVE_NAME="openwrt-armv7-full-${VERSION}.tar.gz"

# 准备发布目录
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "=== 构建 Release 发布包 v${VERSION} ==="

# 1. 写入安装 README（用户解压后第一眼看到）
echo "[1/4] 写入 README.md ..."
cat > "$DIST_DIR/README.md" << 'READMEEOF'
# Docker OpenWrt ARM 32-bit 旁路由部署包

> **适用架构**：arm_cortex-a7_neon-vfpv4（海思 Hi3798MV100 等）  
> **版本**：${VERSION}

---

## 📦 包内容

| 文件 | 说明 |
|------|------|
| `openwrt-armv7.tar` | Docker 镜像（可 docker load 导入） |
| `README.md` | 本文件（安装说明） |
| `fn-knock_*.ipk` | fn-knock 安全网关安装包（可选） |

---

## 🚀 快速开始

### 1. 导入镜像

```bash
docker load -i openwrt-armv7.tar
# 或
gunzip -c openwrt-armv7.tar.gz | docker load
```

### 2. 创建 macvlan 网络

```bash
docker network create -d macvlan \
  --subnet=192.168.3.0/24 \
  --gateway=192.168.3.1 \
  -o parent=eth0 \
  macnet
```

### 3. 启动容器

```bash
docker run -d \
  --name openwrt \
  --restart unless-stopped \
  --network macnet \
  --ip 192.168.3.200 \
  --privileged \
  sulinggg/openwrt:arm_cortex-a7_neon-vfpv4
```

### 4. 宿主机互连

```bash
ip link add macvlan-host link eth0 type macvlan mode bridge
ip addr add 192.168.3.250/24 dev macvlan-host
ip link set macvlan-host up
ip route add 192.168.3.200/32 dev macvlan-host
```

### 5. 登录 Luci

地址: `http://192.168.3.200`  
用户名: `root`  
密码: `admin`（**首次登录立即修改**）

---

## 📖 完整文档

详细部署指南、IPv6 配置、插件清单、fn-knock 部署等：
https://github.com/Blue-Mink/openwrt/tree/master/docs

---

## 🆘 快速排障

| 问题 | 原因 | 解决 |
|------|------|------|
| 宿主机 ping 不通容器 | macvlan 防环机制 | 执行步骤 4 创建 macvlan-host 接口 |
| Luci IPv6 状态显示 ? | 缺 IPv6 网关声明 | `uci add_list network.lan.ip6route='::/0'` 并重启网络 |
| 修改网络后断网 | 在 Luci 中加了网桥 | `ip link del br-xxx` 删除网桥 |
| 容器重启后 IP 变了 | 没固定 `--ip` | 启动时加 `--ip 192.168.3.200` |

---

## 🔗 资源

- GitHub: https://github.com/Blue-Mink/openwrt
- 部署脚本: `scripts/deploy.sh`（完成以上 1-4 步自动化）
READMEEOF

# 替换版本号占位符
sed -i "s/\${VERSION}/${VERSION}/g" "$DIST_DIR/README.md"

# 2. 复制 Docker 镜像导出包（如果存在）
echo "[2/4] 查找 Docker 镜像导出包..."
EXPORT_FILE=""
for f in openwrt-armv7.tar openwrt-armv7.tar.gz; do
  if [ -f "$RELEASE_DIR/$f" ]; then
    EXPORT_FILE="$RELEASE_DIR/$f"
    break
  fi
done

if [ -n "$EXPORT_FILE" ]; then
  cp "$EXPORT_FILE" "$DIST_DIR/"
  echo "  ✅ 已复制: $(basename $EXPORT_FILE) ($(du -h $EXPORT_FILE | cut -f1))"
else
  echo "  ⚠️  未找到 openwrt-armv7.tar(.gz)，发行包不包含 Docker 镜像"
fi

# 3. 复制 fn-knock ipk（如果存在）
echo "[3/4] 查找 fn-knock 安装包..."
for f in fn-knock_*.ipk; do
  if [ -f "$RELEASE_DIR/$f" ]; then
    cp "$RELEASE_DIR/$f" "$DIST_DIR/"
    echo "  ✅ 已复制: $f ($(du -h $RELEASE_DIR/$f | cut -f1))"
  fi
done

# 4. 打包
echo "[4/4] 打包..."
cd "$DIST_DIR"
tar czf "../$ARCHIVE_NAME" .
cd ..

# 清理临时目录
rm -rf "$DIST_DIR"

echo "=== 完成 ==="
echo "发布包: $ARCHIVE_NAME"
ls -lh "$ARCHIVE_NAME"
echo ""
echo "上传到 GitHub Releases 后，用户只需:"
echo "  tar xzf $ARCHIVE_NAME"
echo "  cat README.md   # 所有安装说明就在里面"
