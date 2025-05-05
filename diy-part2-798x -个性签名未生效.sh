#!/bin/bash
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# DIY扩展二合一了，在此处可以增加插件

# 克隆插件
git clone https://github.com/nikkinikki-org/OpenWrt-nikki package/Nikki


# 创建 UCI 默认配置文件目录
mkdir -p package/base-files/files/etc/uci-defaults

# 后台IP设置
Ipv4_ipaddr="192.168.150.2"            # 修改openwrt后台地址
Netmask_netm="255.255.255.0"           # IPv4 子网掩码
Op_name="༄ 目目+࿐"                   # 修改主机名称
echo "CONFIG_IPV4_ADDR=\"$Ipv4_ipaddr\"" >> .config
echo "CONFIG_NETMASK_NETM=\"$Netmask_netm\"" >> .config
echo "CONFIG_OP_NAME=\"$Op_name\"" >> .config
cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
uci set network.lan.ipaddr='$Ipv4_ipaddr'
uci set network.lan.netmask='$Netmask_netm'
uci set system.@system[0].hostname='$Op_name'
uci commit
EOF

# 内核和系统分区大小
Kernel_partition_size="0"               # 内核分区大小 (MB)
Rootfs_partition_size="0"               # 系统分区大小 (MB)
echo "CONFIG_KERNEL_PARTITION_SIZE=\"$Kernel_partition_size\"" >> .config
echo "CONFIG_ROOTFS_PARTITION_SIZE=\"$Rootfs_partition_size\"" >> .config

# 默认主题设置
Mandatory_theme="argon"                 # 必选主题
Default_theme="argon"                   # 默认第一主题
echo "CONFIG_MANDATORY_THEME=\"$Mandatory_theme\"" >> .config
echo "CONFIG_DEFAULT_THEME=\"$Default_theme\"" >> .config

# 旁路由选项
Gateway_Settings="192.168.150.1"       # IPv4 网关
DNS_Settings="192.168.151.2 223.5.5.5" # DNS 设置
Broadcast_Ipv4="0"                      # IPv4 广播
Disable_DHCP="1"                        # 关闭 DHCP
Disable_Bridge="1"                      # 去掉桥接模式
Create_Ipv6_Lan="0"                     # 创建 IPv6 LAN
echo "CONFIG_GATEWAY_SETTINGS=\"$Gateway_Settings\"" >> .config
echo "CONFIG_DNS_SETTINGS=\"$DNS_Settings\"" >> .config
echo "CONFIG_BROADCAST_IPV4=\"$Broadcast_Ipv4\"" >> .config
echo "CONFIG_DISABLE_DHCP=\"$Disable_DHCP\"" >> .config
echo "CONFIG_DISABLE_BRIDGE=\"$Disable_Bridge\"" >> .config
echo "CONFIG_CREATE_IPV6_LAN=\"$Create_Ipv6_Lan\"" >> .config
cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
[ "$Gateway_Settings" != "0" ] && uci set network.lan.gateway='$Gateway_Settings'
[ "$DNS_Settings" != "0" ] && uci set network.lan.dns='$DNS_Settings'
[ "$Disable_DHCP" = "1" ] && uci set dhcp.lan.ignore='1'
[ "$Disable_Bridge" = "1" ] && uci delete network.lan.type
uci commit
EOF

# IPV6、IPV4 选择
Enable_IPV6_function="0"                # 启用 IPv6
Enable_IPV4_function="0"                # 启用 IPv4
if [ "$Enable_IPV6_function" = "1" ] && [ "$Enable_IPV4_function" = "1" ]; then
    Enable_IPV4_function="0"            # 互斥处理
fi
[ "$Enable_IPV6_function" = "1" ] && Create_Ipv6_Lan="0"  # 互斥处理
echo "CONFIG_ENABLE_IPV6_FUNCTION=\"$Enable_IPV6_function\"" >> .config
echo "CONFIG_ENABLE_IPV4_FUNCTION=\"$Enable_IPV4_function\"" >> .config

# 替换 OpenClash 的源码
OpenClash_branch="0"                    # 0 为 master 分支，1 为 dev 分支
echo "CONFIG_OPENCLASH_BRANCH=\"$OpenClash_branch\"" >> .config

# 个性签名
Customized_Information="༄ 目目+࿐$(TZ=UTC-8 date '+%Y.%m.%d')"  # 个性签名
echo "CONFIG_CUSTOMIZED_INFORMATION=\"$Customized_Information\"" >> .config
[ -f package/lean/default-settings/files/zzz-default-settings ] && \
    sed -i "s/OpenWrt /Custom Build $Customized_Information /g" package/lean/default-settings/files/zzz-default-settings

# 更换固件内核
Replace_Kernel="0"                      # 更换内核版本
echo "CONFIG_REPLACE_KERNEL=\"$Replace_Kernel\"" >> .config

# 设置免密码登录
Password_free_login="1"                 # 首次登录无密码
echo "CONFIG_PASSWORD_FREE_LOGIN=\"$Password_free_login\"" >> .config
[ "$Password_free_login" = "1" ] && \
    cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
uci delete system.@system[0].password
uci commit system
EOF

# 增加 AdGuardHome 插件和核心
AdGuardHome_Core="0"                    # 增加 AdGuardHome
echo "CONFIG_ADGUARDHOME_CORE=\"$AdGuardHome_Core\"" >> .config

# 禁用 NaiveProxy
Disable_NaiveProxy="0"                  # 禁用 NaiveProxy
echo "CONFIG_DISABLE_NAIVEPROXY=\"$Disable_NaiveProxy\"" >> .config

# 开启 NTFS 格式盘挂载
Automatic_Mount_Settings="0"            # NTFS 挂载支持
echo "CONFIG_AUTOMATIC_MOUNT_SETTINGS=\"$Automatic_Mount_Settings\"" >> .config

# 去除网络共享 (autosamba)
Disable_autosamba="1"                   # 去掉 autosamba
echo "CONFIG_DISABLE_AUTOSAMBA=\"$Disable_autosamba\"" >> .config

# 其他设置
Ttyd_account_free_login="0"             # ttyd 免密登录
Delete_unnecessary_items="0"            # 删除多余固件
Disable_53_redirection="0"              # 删除 DNS 53 重定向
Cancel_running="0"                      # 取消跑分任务
echo "CONFIG_TTYD_ACCOUNT_FREE_LOGIN=\"$Ttyd_account_free_login\"" >> .config
echo "CONFIG_DELETE_UNNECESSARY_ITEMS=\"$Delete_unnecessary_items\"" >> .config
echo "CONFIG_DISABLE_53_REDIRECTION=\"$Disable_53_redirection\"" >> .config
echo "CONFIG_CANCEL_RUNNING=\"$Cancel_running\"" >> .config
[ "$Ttyd_account_free_login" = "1" ] && \
    cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
uci set ttyd.@ttyd[0].command='/bin/sh -l'
uci commit ttyd
EOF

# 晶晨 CPU 系列打包固件设置
amlogic_model="s905d"
amlogic_kernel="5.10.01_6.1.01"
auto_kernel="true"
rootfs_size="2560"
kernel_usage="stable"
echo "CONFIG_AMLOGIC_MODEL=\"$amlogic_model\"" >> .config
echo "CONFIG_AMLOGIC_KERNEL=\"$amlogic_kernel\"" >> .config
echo "CONFIG_AUTO_KERNEL=\"$auto_kernel\"" >> .config
echo "CONFIG_ROOTFS_SIZE=\"$rootfs_size\"" >> .config
echo "CONFIG_KERNEL_USAGE=\"$kernel_usage\"" >> .config

# 修改插件名字
[ -d package ] && find package/ -type f -exec sed -i 's/"终端"/"终端TTYD"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"网络存储"/"NAS"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"实时流量监测"/"流量"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"KMS 服务器"/"KMS激活"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"USB 打印服务器"/"打印服务"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"Web 管理"/"Web管理"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"管理权"/"管理权"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"带宽监控"/"带宽监控"/g' {} +

# 清理不需要的文件
CLEAR_PATH="./clear_list.txt"
cat > "$CLEAR_PATH" << EOF
packages
config.buildinfo
feeds.buildinfo
sha256sums
version.buildinfo
profiles.json
openwrt-x86-64-generic-kernel.bin
openwrt-x86-64-generic.manifest
openwrt-x86-64-generic-squashfs-rootfs.img.gz
EOF

# 在线更新时删除文件
DELETE="./delete_list.txt"
cat > "$DELETE" << EOF
EOF