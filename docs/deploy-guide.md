# Docker OpenWrt 旁路由部署指南

> **宿主机架构**：ARMv7 32-bit（armv7l）  
> **CPU**：海思 Hi3798MV100，4核 Cortex-A7 @ 1.5GHz  
> **OS**：Ubuntu 20.04 LTS  
> **内核**：Linux 4.4.35  
> **容器 IP**：192.168.3.A  
> **宿主机网口**：eth0（有线）

---

## 一、获取镜像

### 方式一：从 Docker Hub 拉取

```bash
docker pull sulinggg/openwrt:arm_cortex-a7_neon-vfpv4
```

镜像大小约 75MB，运行层约 150MB。

### 方式二：从 Release 离线导入

如果设备无法直接访问 Docker Hub，可从仓库 Release 下载镜像包后导入：

```bash
# 下载 https://github.com/Blue-Mink/openwrt/releases/download/v1.0.0/openwrt-armv7.tar.gz
# 上传到设备后执行：
gunzip -c openwrt-armv7.tar.gz | docker load
```

## 二、创建 macvlan 网络

```bash
docker network create -d macvlan \
  --subnet=192.168.3.0/24 \
  --gateway=192.168.3.1 \
  -o parent=eth0 \
  macnet
```

## 三、启动容器

```bash
docker run -d \
  --name openwrt \
  --restart unless-stopped \
  --network macnet \
  --ip 192.168.3.A \
  --privileged \
  sulinggg/openwrt:arm_cortex-a7_neon-vfpv4
```

**参数说明**：

| 参数 | 说明 |
|------|------|
| `--restart unless-stopped` | 容器崩溃/宿主机重启自动拉起；手动 stop 后尊重停止意图 |
| `--privileged` | 完整网络控制权（iptables、ip6tables、WireGuard 等需要） |
| `--network macnet` | 接入 macvlan 网络，容器与宿主机同网段 |
| `--ip 192.168.3.A` | 固定 IP，避免重启后 DHCP 变地址 |

## 四、宿主机与容器互通配置

macvlan 模式下宿主机默认无法访问 macvlan 容器，需在宿主机上创建虚拟接口：

```bash
# 创建 macvlan-host 虚拟接口
ip link add macvlan-host link eth0 type macvlan mode bridge
ip addr add 192.168.3.B/24 dev macvlan-host
ip link set macvlan-host up
ip route add 192.168.3.A/32 dev macvlan-host
```

- `192.168.3.A` 是容器 IP
- `192.168.3.B` 是宿主机虚拟接口 IP（与容器不同即可）

## 五、固化开机自启

编辑宿主机 `/etc/rc.local`，在 `exit 0` 前加入：

```bash
ip link add macvlan-host link eth0 type macvlan mode bridge 2>/dev/null
ip addr add 192.168.3.B/24 dev macvlan-host 2>/dev/null
ip link set macvlan-host up
ip route add 192.168.3.A/32 dev macvlan-host
```

## 六、首次登录修改密码

进入容器修改默认密码（安全第一步）：

```bash
docker exec -it openwrt passwd
```

然后访问 `http://192.168.3.A`，用 `root` 和新密码登录。

## 七、配置 OpenWrt 软件源

进入容器：

```bash
docker exec -it openwrt sh
```

编辑 `/etc/opkg/distfeeds.conf`，替换内容为 OpenWrt 19.07.10 稳定源：

```
src/gz openwrt_base http://archive.openwrt.org/releases/19.07.10/packages/arm_cortex-a7_neon-vfpv4/base
src/gz openwrt_luci http://archive.openwrt.org/releases/19.07.10/packages/arm_cortex-a7_neon-vfpv4/luci
src/gz openwrt_packages http://archive.openwrt.org/releases/19.07.10/packages/arm_cortex-a7_neon-vfpv4/packages
src/gz openwrt_routing http://archive.openwrt.org/releases/19.07.10/packages/arm_cortex-a7_neon-vfpv4/routing
src/gz openwrt_telephony http://archive.openwrt.org/releases/19.07.10/packages/arm_cortex-a7_neon-vfpv4/telephony
```

在 `/etc/opkg/opkg.conf` 中添加：

```
option check_signature 0
```

更新源：

```bash
opkg update
```

## 八、安装必要插件

```bash
opkg install luci-i18n-base-zh-cn \
  luci-app-passwall \
  luci-app-smartdns \
  luci-app-autoreboot \
  luci-app-nlbwmon \
  luci-app-filetransfer
```

## 九、旁路由使用

将局域网设备的默认网关指向容器 IP `192.168.3.A`：

```
IP 地址：    192.168.3.X（主路由 DHCP 分配）
子网掩码：   255.255.255.0
默认网关：   192.168.3.A  ← 旁路由
DNS 服务器： 192.168.3.A
```

## 十、管理命令

```bash
docker logs openwrt              # 查看日志
docker exec -it openwrt sh       # 进入容器 shell
docker restart openwrt           # 重启容器
docker stop openwrt              # 停止
docker start openwrt             # 启动

# 宿主机验证
ping 192.168.3.A                # 连通性
curl http://192.168.3.A         # Luci 访问
```
