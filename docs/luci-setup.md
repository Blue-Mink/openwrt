# LuCI 管理界面配置与插件清单

> OpenWrt 容器的 Web 管理界面配置、预装插件与推荐插件清单。

---

## 一、登录信息

| 项目 | 值 |
|------|-----|
| **地址** | `http://192.168.3.A` |
| **用户名** | `root` |
| **密码** | `admin`（**首次登录请立即修改**） |

**修改密码**：

```bash
docker exec -it openwrt passwd
```

## 二、⚠️ 硬件限制提醒

| 限制项 | 说明 |
|--------|------|
| **RAM** | 仅 720MB，**不要同时装多个科学上网插件**（PassWall + SSR-Plus + OpenClash 同时运行会 OOM） |
| **存储** | 容器内剩余空间有限，插件装太多会存满 |
| **虚拟接口** | **不要在 Luci 网络 → 接口 中添加新网桥**，Docker 容器不允许修改内核级网桥，加了会断网，只能通过 ip link 在宿主机操作 |

> **推荐方案**：只装 **PassWall + SmartDNS**，轻量稳定，已足够日常使用。

## 三、预装插件（27+）

镜像自带的核心插件套装：

| 类别 | 插件 |
|------|------|
| 🌐 科学上网 | PassWall、SSR-Plus、OpenClash、V2Ray、Trojan |
| 📥 下载工具 | Aria2、Transmission |
| 🔗 内网穿透 | FRPC、NPS、ZeroTier、n2n |
| 📡 DNS | SmartDNS、DDNS（阿里云/Cloudflare/DNSPod 等） |
| 📊 监控 | Netdata、WRTbwmon、NLBwmon |
| 🔒 VPN | WireGuard、SoftEtherVPN、HAProxy |
| 🛠 系统 | Samba、TurboACC、ttyd、FileAssistant、ServerChan |

LuCI 完整菜单含 **37 个功能模块**，涵盖：

- **Status** — 概览、防火墙、路由表、系统日志、进程、实时图表、WireGuard 状态
- **System** — Web 管理、管理权限、NetData、软件包、TTYD 终端、启动项、计划任务、挂载点、备份/升级、文件传输、Argon 主题配置
- **Services** — PassWall、SSR-Plus、微信推送、OpenClash、DDNS、SmartDNS、FRP、NPS、文件助手、Aria2、GoWebDav、网络共享、Transmission
- **VPN** — N2N、SoftEther、ZeroTier
- **Network** — 接口、DHCP/DNS、主机名、路由、诊断、防火墙、TurboACC、带宽监控

## 四、推荐插件安装

```bash
# 中文界面
opkg install luci-i18n-base-zh-cn

# 科学上网（选一个即可，推荐 PassWall）
opkg install luci-app-passwall

# DNS 优化
opkg install luci-app-smartdns

# 定时重启（释放内存）
opkg install luci-app-autoreboot

# 流量监控
opkg install luci-app-nlbwmon

# 文件管理
opkg install luci-app-filetransfer
```

## 五、配置建议

### 5.1 时区设置

Luci → System → System → Timezone → `Asia/Shanghai`

### 5.2 修改 HTTPS 端口（可选）

Luci → System → Web Admin → 修改端口为 8443 或其他。

### 5.3 固件更新与备份

建议在 Luci → System → Backup/Flash Firmware 中定期备份配置。

### 5.4 PassWall 配置流程

1. 进入 Services → PassWall
2. 主开关 → 启用
3. DNS → 选择 dns2socks/ChinaDNS
4. 节点列表 → 添加订阅/手动添加服务器
5. 规则管理 → 选择 gfwlist/绕过中国大陆 IP
6. 应用并重启相关服务
