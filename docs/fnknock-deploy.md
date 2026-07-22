# fn-knock 安全网关部署（Docker OpenWrt）

> 在 OpenWrt 容器内安装 fn-knock 敲门安全网关，为内网服务提供安全的公网访问入口。

---

## 一、下载 ipk 包

从 GitHub Releases 下载对应架构的 ipk 包：

```bash
# arm_cortex-a7_neon-vfpv4 架构
wget https://github.com/blue-mink/fn-knock-turborepo/releases/download/v2.0.8/fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

国内用户可用 ghproxy 镜像加速：

```bash
wget https://ghproxy.net/https://github.com/blue-mink/fn-knock-turborepo/releases/download/v2.0.8/fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

## 二、安装到 OpenWrt 容器

### 2.1 传入文件

```bash
docker cp fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk openwrt:/tmp/
```

### 2.2 常规安装（可能因依赖缺失失败）

```bash
docker exec -it openwrt sh
cd /tmp
opkg update
opkg install fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

### 2.3 强制安装（Docker 环境推荐）

```bash
opkg install --force-depends fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

## 三、依赖缺失说明

fn-knock 声明了 3 个系统依赖，但在 Docker 环境中均不影响运行：

### 3.1 iptables-nft / ip6tables-nft

| 项目 | 说明 |
|------|------|
| **声明依赖** | `iptables-nft`, `ip6tables-nft`（nftables 后端的 iptables） |
| **实际情况** | Docker 容器基于 ImmortalWrt 18.06，默认使用 **iptables-legacy** |
| **为什么不影响** | fn-knock 的 `go-reauth-proxy` 仅通过 PATH 调用 `iptables` 命令，不区分 legacy 还是 nft 后端。legacy 版完全兼容 |
| **结论** | ✅ 无需安装，功能完整 |

### 3.2 kmod-nft-compat

| 项目 | 说明 |
|------|------|
| **声明依赖** | `kmod-nft-compat`（内核 nftables 兼容模块） |
| **实际情况** | 宿主机内核中 `nf_tables` 为 **builtin**（静态编译），非可加载模块 |
| **为什么不影响** | Docker 容器共享宿主机内核，nftables 框架完全可用，无需额外加载内核模块 |
| **结论** | ✅ 无需安装，功能完整 |

### 3.3 实际验证结果

| 验证项 | 结果 |
|--------|:----:|
| `go-reauth-proxy` (7999) | ✅ HTTP 200，正常运行 |
| `server-admin-rs` (7991/7997/17998) | ✅ 正常运行 |
| iptables `FN-KNOCK-FW` 链 (IPv4) | ✅ 规则完整，有流量命中 |
| ip6tables `FN-KNOCK-FW` 链 (IPv6) | ✅ 规则完整 |
| 日志 iptables 错误 | ❌ **无任何 iptables 相关错误** |

## 四、验证安装

```bash
# 检查进程
ps | grep -E "go-reauth|server-admin"

# 检查端口
netstat -tlnp | grep -E "7991|7997|7999|17998"

# 检查 iptables 规则
iptables -L FN-KNOCK-FW -n
ip6tables -L FN-KNOCK-FW -n
```

## 五、访问管理界面

| 端口 | 用途 | 地址 |
|:----:|------|------|
| 7999 | 公网入口（go-reauth-proxy） | `http://192.168.3.A:7999` |
| 7991 | 管理面板（server-admin-rs） | `http://192.168.3.A:7991` |
| 7997 | 备用管理端口 | `http://192.168.3.A:7997` |

## 六、LuCI 菜单入口

安装后自动生成 Services → Knock 菜单项。

若 Luci 菜单未显示（ImmortalWrt 18.06 可能缺 Lua controller），手动创建：

```bash
# 创建控制器文件
cat > /usr/lib/lua/luci/controller/knock.lua << 'LUCIEOF'
module("luci.controller.knock", package.seeall)

function index()
    entry({"admin", "services", "knock"}, alias("admin", "services", "knock"), _("敲门 Knock"), 90)
    entry({"admin", "services", "knock", "admin"}, template("admin_knock/knock"), _("管理面板"), 1).leaf = true
end
LUCIEOF

# 重启 Luci
/etc/init.d/uhttpd restart
```
