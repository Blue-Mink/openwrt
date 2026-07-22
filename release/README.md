# Release 安装包

> OpenWrt ARM 32-bit 相关的安装包与发布说明。

---

## 文件清单

| 文件 | 说明 | 来源 |
|------|------|------|
| `openwrt-armv7.tar.gz` | OpenWrt Docker 镜像导出包 | 通过 `docker save` 导出（见 docker/ 目录） |
| `openwrt-armv7-full-v1.0.0.tar.gz` | ⭐ **完整发布包**（镜像 + README 安装说明） | 通过 `scripts/build-release.sh` 构建 |
| `fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk` | fn-knock 敲门安全网关安装包（可选） | [GitHub Releases](https://github.com/blue-mink/fn-knock-turborepo/releases) |

> **💡 推荐下载 `openwrt-armv7-full-*.tar.gz`**，解压后自带 README 安装说明，无需翻 GitHub 文档：
> ```bash
> tar xzf openwrt-armv7-full-v1.0.0.tar.gz
> ls -l   # 即可看到 README.md + openwrt-armv7.tar + fn-knock_*.ipk
> cat README.md   # 所有安装步骤就在当前目录
> ```

## 快速安装（从完整发布包）

```bash
# 1. 解压
tar xzf openwrt-armv7-full-v1.0.0.tar.gz

# 2. 导入镜像
docker load -i openwrt-armv7.tar

# 3. 创建 macvlan 网络
docker network create -d macvlan \
  --subnet=192.168.3.0/24 \
  --gateway=192.168.3.1 \
  -o parent=eth0 \
  macnet

# 4. 启动容器（IP 替换为你的实际地址）
docker run -d \
  --name openwrt \
  --restart unless-stopped \
  --network macnet \
  --privileged \
  sulinggg/openwrt:arm_cortex-a7_neon-vfpv4

# 5. 登录 Luci: http://容器IP，root/admin
#    首次登录立即修改密码
```

## 架构验证

所有安装包仅适用于 **arm_cortex-a7_neon-vfpv4** 架构：

```bash
docker exec openwrt cat /proc/cpuinfo | grep "Hardware"
# 应为 Hi3798MV100 系列
```

## 构建自己的发布包

用仓库的构建脚本打包（含 README）：

```bash
git clone https://github.com/Blue-Mink/openwrt.git
cd openwrt
# 先导出 Docker 镜像到 release/ 目录
docker save sulinggg/openwrt:arm_cortex-a7_neon-vfpv4 -o release/openwrt-armv7.tar
# 运行构建脚本
bash scripts/build-release.sh v1.0.0
# 生成 dist/openwrt-armv7-full-v1.0.0.tar.gz
```

## 版本更新

关注 [GitHub Releases](https://github.com/Blue-Mink/openwrt/releases) 获取最新版本。
