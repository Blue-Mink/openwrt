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

## 十、IPv6 配置与排坑

> 部署过程中遇到了两个 IPv6 的实际问题，下面一并说明。

### 问题 1：IPv6 地址冲突（ipvlan 模式）

**现象**：容器获取 IPv6 SLAAC 地址后，与宿主机 IPv6 地址相同，导致网络不稳定。

**根因**：如果使用 **ipvlan L2** 模式，容器共享宿主机 MAC 地址。主路由 SLAAC 根据 MAC 生成 IPv6 地址后缀（EUI-64），宿主机和容器拿到同一个地址 → 地址冲突。

**解法**：使用 **macvlan** 模式（本项目默认方案），每个容器有独立 MAC，SLAAC 自动分配唯一 IPv6 地址。

```bash
# macvlan 模式下检查容器的 IPv6 地址（应是唯一的）
docker exec openwrt ip -6 addr show eth0

# 如果还出现冲突，可手动指定 IPv6 地址
docker exec openwrt sh -c "
  uci set network.lan.ip6assign='64'
  uci set network.lan.ip6hint='A'   # 或自定义后缀
  uci commit network
  /etc/init.d/network restart
"
```

### 问题 2：Luci 页面 IPv6 WAN Status 显示 "? Not connected"

**现象**：Luci 概览页 → IPv6 WAN Status 显示 `? Not connected`，但实际 `ping6` 外网是通的。

**根因**：Luci 的 `get_wan6net()` 函数在 `lan` 接口的 ubus 数据中寻找 IPv6 默认路由。由于 Docker 容器的 IPv6 默认路由由内核自动添加（fe80::1 dev eth0），但 `/etc/config/network` 中 `lan` 段**没有显式声明 IPv6 网关**，ubus 数据里找不到 → 显示 `?`。

**修复**：在 `/etc/config/network` 的 `lan` 段添加两行：

```bash
docker exec -it openwrt sh -c "
  uci add_list network.lan.ip6route='::/0'
  uci set network.lan.ip6gw='fe80::1'
  uci commit network
  /etc/init.d/network restart
"
```

修复后 Luci 正确显示 IPv6 地址和网关信息。

### 常见 IPv6 检查命令

```bash
# 检查容器 IPv6 地址
docker exec openwrt ip -6 addr show

# 检查 IPv6 路由
docker exec openwrt ip -6 route show

# 测试 IPv6 连通性
docker exec openwrt ping6 -c 3 2400:3200::1
docker exec openwrt ping6 -c 3 2001:4860:4860::8888

# 查看 Luci 状态页
curl -s http://192.168.3.A/cgi-bin/luci/admin/status/overview 2>/dev/null | grep -i ipv6
```

## 十一、管理命令

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
