# fn-knock 安全网关部署（Docker OpenWrt）

> 在 OpenWrt 容器内安装 fn-knock 敲门安全网关，为内网服务提供安全的公网访问入口。

---

## 一、下载 ipk 包

从 [fn-knock Releases](https://github.com/blue-mink/fn-knock-turborepo/releases) 下载对应架构的 ipk 包：

```bash
# arm_cortex-a7_neon-vfpv4 架构
wget https://github.com/blue-mink/fn-knock-turborepo/releases/download/v2.0.8/fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

也可通过 ghproxy 镜像加速：

```bash
wget https://ghproxy.net/https://github.com/blue-mink/fn-knock-turborepo/releases/download/v2.0.8/fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

## 二、安装到 OpenWrt 容器

将 ipk 文件传入容器并安装：

```bash
# 宿主机 → 容器
docker cp fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk openwrt:/tmp/

# 进入容器安装
docker exec -it openwrt sh
cd /tmp
opkg update
opkg install fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

**注意**：Docker 容器中 iptables-nft 不可用，使用 `--force-depends` 跳过无关依赖：

```bash
opkg install --force-depends fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

## 三、验证安装

```bash
# 检查进程
ps | grep -E "go-reauth|server-admin"

# 检查端口
netstat -tlnp | grep -E "7991|7997|7999|17998"

# 检查 iptables 规则
iptables -L FN-KNOCK-FW -n
ip6tables -L FN-KNOCK-FW -n
```

## 四、访问管理界面

| 端口 | 用途 | 地址 |
|:----:|------|------|
| 7999 | 公网入口（go-reauth-proxy） | `http://192.168.3.A:7999` |
| 7991 | 管理面板（server-admin-rs） | `http://192.168.3.A:7991` |
| 7997 | 备用管理端口 | `http://192.168.3.A:7997` |

## 五、LuCI 菜单入口

安装后自动生成 Services → Knock 菜单项。

若 Luci 菜单未显示（ImmortalWrt 18.06 可能缺 Lua controller），手动创建：

```bash
# 创建控制器文件
cat > /usr/lib/lua/luci/controller/knock.lua << 'EOF'
module("luci.controller.knock", package.seeall)

function index()
    entry({"admin", "services", "knock"}, alias("admin", "services", "knock"), _("敲门 Knock"), 90)
    entry({"admin", "services", "knock", "admin"}, template("admin_knock/knock"), _("管理面板"), 1).leaf = true
end
EOF

# 重启 Luci
/etc/init.d/uhttpd restart
```

## 六、依赖说明

fn-knock 声明的 3 个依赖在实际 Docker 环境中均不影响运行：

| 声明依赖 | 实际影响 |
|----------|----------|
| `iptables-nft` / `ip6tables-nft` | fn-knock 通过 PATH 调用 `iptables`，不区分 legacy/nft 后端。Docker 容器已有 iptables-legacy |
| `kmod-nft-compat` | 宿主机内核 `nf_tables` 为 builtin，容器共享内核，nftables 框架完全可用 |
