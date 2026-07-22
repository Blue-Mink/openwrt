# Docker OpenWrt 旁路由部署（ARM 32-bit）

> 在 **ARMv7 32-bit（armv7l）** 设备上通过 Docker 部署 OpenWrt 旁路由的完整方案。

## 项目内容

| 目录/文件 | 说明 |
|-----------|------|
| `docs/deploy-guide.md` | Docker OpenWrt 旁路由部署指南 |
| `docs/fnknock-deploy.md` | fn-knock 敲门安全网关部署配置 |
| `docs/luci-setup.md` | Luci Web 界面配置与插件清单 |
| `docker/` | Docker 构建文件与镜像导出流程 |
| `release/` | 发布包与安装指南 |
| `scripts/` | 自动化部署脚本 |

## 硬件环境

| 项目 | 规格 |
|------|------|
| **CPU** | 海思 Hi3798MV100，4核 Cortex-A7 @ 1.5GHz |
| **架构** | ARMv7 32-bit（arm_cortex-a7_neon-vfpv4） |
| **RAM** | 720MB |
| **OS** | Ubuntu 20.04 LTS |
| **内核** | Linux 4.4.35 |

## 快速开始

```bash
# 1. 拉取镜像
docker pull sulinggg/openwrt:arm_cortex-a7_neon-vfpv4

# 2. 创建 macvlan 网络
docker network create -d macvlan \
  --subnet=192.168.3.0/24 \
  --gateway=192.168.3.1 \
  -o parent=eth0 \
  macnet

# 3. 启动容器
docker run -d \
  --name openwrt \
  --restart unless-stopped \
  --network macnet \
  --ip 192.168.3.A \
  --privileged \
  sulinggg/openwrt:arm_cortex-a7_neon-vfpv4

# 4. 配置宿主机互通
ip link add macvlan-host link eth0 type macvlan mode bridge
ip addr add 192.168.3.B/24 dev macvlan-host
ip link set macvlan-host up
ip route add 192.168.3.A/32 dev macvlan-host
```

> 详细步骤见 [部署指南](docs/deploy-guide.md)

## 功能组件

- **OpenWrt 旁路由** — 科学上网、DNS 优化、流量管理
- **macvlan 网络** — 容器独立局域网身份，宿主机互通
- **fn-knock 安全网关** — 自托管 NAS/fnOS 公网访问安全网关
- **LuCI 管理界面** — 37+ 预装插件，Web 图形化管理
