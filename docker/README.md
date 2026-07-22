# Docker 镜像与构建

> OpenWrt ARM 32-bit（arm_cortex-a7_neon-vfpv4）Docker 镜像的获取、使用与构建说明。

---

## 一、获取镜像

### 方式一：从 Docker Hub 拉取（推荐）

```bash
docker pull sulinggg/openwrt:arm_cortex-a7_neon-vfpv4
```

### 方式二：离线导入

在能连接 Docker Hub 的环境先保存：

```bash
# 导出镜像为 tar 包
docker save sulinggg/openwrt:arm_cortex-a7_neon-vfpv4 -o openwrt-armv7.tar

# 压缩（可选）
gzip openwrt-armv7.tar

# 在目标设备导入
docker load -i openwrt-armv7.tar
# 或
gunzip -c openwrt-armv7.tar.gz | docker load
```

### 方式三：自行构建

参考本目录下的 `Dockerfile` 自行构建镜像。

## 二、镜像信息

| 项目 | 值 |
|------|-----|
| **镜像名** | `sulinggg/openwrt:arm_cortex-a7_neon-vfpv4` |
| **基础系统** | ImmortalWrt 18.06-k5.4-SNAPSHOT |
| **架构** | arm_cortex-a7_neon-vfpv4 |
| **内核** | 共享宿主机内核（Docker 容器） |
| **包管理器** | opkg |
| **预装插件** | 27+ 个核心插件 |
| **镜像大小** | ~75MB（压缩） |

## 三、多架构支持说明

| 架构 | 镜像 | 说明 |
|------|------|------|
| arm_cortex-a7 (32-bit) | `sulinggg/openwrt:arm_cortex-a7_neon-vfpv4` | ✅ 本项目适用 |
| arm64 (aarch64) | `sulinggg/openwrt:arm64_armv8-a` | 64位 ARM 设备 |
| amd64 (x86_64) | `openwrt/rootfs:latest`（官方） | x86 设备 |

## 四、导出脚本

参考 [`scripts/export-image.sh`](../scripts/export-image.sh) 一键导出镜像包。

## 五、验证镜像完整性

```bash
# 查看镜像信息
docker images sulinggg/openwrt

# 检查架构
docker inspect sulinggg/openwrt:arm_cortex-a7_neon-vfpv4 | grep Architecture

# 启动并检查
docker run --rm sulinggg/openwrt:arm_cortex-a7_neon-vfpv4 cat /proc/cpuinfo
```
