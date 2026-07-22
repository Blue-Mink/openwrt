# Release 安装包

> OpenWrt ARM 32-bit 相关的安装包与发布说明。

---

## 文件清单

| 文件 | 说明 | 来源 |
|------|------|------|
| `fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk` | fn-knock 敲门安全网关安装包 | [GitHub Releases](https://github.com/blue-mink/fn-knock-turborepo/releases) |
| `openwrt-armv7.tar.gz` | OpenWrt Docker 镜像导出包 | 通过 `docker save` 导出（见 docker/ 目录） |

## fn-knock ipk 安装

```bash
# 上传到容器
docker cp fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk openwrt:/tmp/

# 进入容器安装
docker exec -it openwrt sh
opkg update
opkg install --force-depends /tmp/fn-knock_2.0.8-1_arm_cortex-a7_neon-vfpv4.ipk
```

## Docker 镜像导入

```bash
# 解压并导入
gunzip -c openwrt-armv7.tar.gz | docker load

# 验证
docker images | grep openwrt
```

## 架构验证

所有安装包仅适用于 **arm_cortex-a7_neon-vfpv4** 架构：

```bash
docker exec openwrt cat /proc/cpuinfo | grep "Hardware"
# 应为 Hi3798MV100 系列
```

## 版本更新

关注 [GitHub Releases](https://github.com/Blue-Mink/openwrt/releases) 获取最新版本。
