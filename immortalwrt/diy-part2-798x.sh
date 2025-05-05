#!/bin/bash
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# DIY扩展二合一了，在此处可以增加插件

echo "开始 DIY2 配置……"
echo "========================="

chmod +x ${GITHUB_WORKSPACE}/immortalwrt/function.sh
source ${GITHUB_WORKSPACE}/immortalwrt/function.sh

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

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 修复上移下移按钮翻译
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm

# 修复procps-ng-top导致首页cpu使用率无法获取
sed -i 's#top -n1#\/bin\/busybox top -n1#g' feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci

# ------------------PassWall 科学上网--------------------------
# 移除 openwrt feeds 自带的核心库
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box,pdnsd-alt,chinadns-ng,dns2socks,dns2tcp,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview}
# 核心库
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
rm -rf package/passwall-packages/{shadowsocks-rust,v2ray-geodata}
merge_package v5 https://github.com/sbwml/openwrt_helloworld package/passwall-packages shadowsocks-rust v2ray-geodata
# app
rm -rf feeds/luci/applications/{luci-app-passwall,luci-app-ssr-libev-server}
# git clone https://github.com/lwb1978/openwrt-passwall package/passwall-luci
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
# ------------------------------------------------------------

# Passwall2
rm -rf feeds/luci/applications/luci-app-passwall2
git clone https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2

# Nikki
rm -rf feeds/luci/applications/luci-app-nikki
git clone https://github.com/nikkinikki-org/OpenWrt-nikki package/luci-app-nikki

# homeproxy
rm -rf feeds/luci/applications/luci-app-homeproxy
git clone https://github.com/immortalwrt/homeproxy package/luci-app-homeproxy

# luci-app-turboacc
rm -rf feeds/luci/applications/luci-app-turboacc
git clone https://github.com/chenmozhijin/turboacc package/luci-app-turboacc

# 优化socat中英翻译
sed -i 's/仅IPv6/仅 IPv6/g' package/feeds/luci/luci-app-socat/po/zh_Hans/socat.po

# 替换udpxy为修改版，解决组播源数据有重复数据包导致的花屏和马赛克问题
rm -rf feeds/packages/net/udpxy/Makefile
cp -rf ${GITHUB_WORKSPACE}/patch/udpxy/Makefile feeds/packages/net/udpxy/

# 修改 udpxy 菜单名称为大写
sed -i 's#\"title\": \"udpxy\"#\"title\": \"UDPXY\"#g' feeds/luci/applications/luci-app-udpxy/root/usr/share/luci/menu.d/luci-app-udpxy.json

# lukcy大吉
git clone https://github.com/sirpdboy/luci-app-lucky package/lucky-packages
# git clone https://github.com/gdy666/luci-app-lucky.git package/lucky-packages

# 添加主题
rm -rf feeds/luci/themes/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
# merge_package openwrt-23.05 https://github.com/sbwml/luci-theme-argon package luci-theme-argon
# merge_package openwrt-24.10 https://github.com/sbwml/luci-theme-argon package luci-theme-argon
git clone --depth=1 -b js https://github.com/sirpdboy/luci-theme-kucat package/luci-theme-kucat
git clone --depth=1 -b main https://github.com/sirpdboy/luci-app-advancedplus  package/luci-app-advancedplus
# 取消自添加主题的默认设置
find package/luci-theme-*/* -type f -print | grep '/root/etc/uci-defaults/' | while IFS= read -r file; do
	sed -i '/set luci.main.mediaurlbase/d' "$file"
done

# 设置默认主题
default_theme='argon'
sed -i "s/bootstrap/$default_theme/g" feeds/luci/modules/luci-base/root/etc/config/luci

# 内核和系统分区大小
Kernel_partition_size="0"               # 内核分区大小 (MB)
Rootfs_partition_size="0"               # 系统分区大小 (MB)
echo "CONFIG_KERNEL_PARTITION_SIZE=\"$Kernel_partition_size\"" >> .config
echo "CONFIG_ROOTFS_PARTITION_SIZE=\"$Rootfs_partition_size\"" >> .config

# 旁路由选项
# Gateway_Settings="192.168.150.1"       # IPv4 网关
# DNS_Settings="192.168.151.2 223.5.5.5" # DNS 设置
# Broadcast_Ipv4="0"                      # IPv4 广播
# Disable_DHCP="1"                        # 关闭 DHCP
# Disable_Bridge="1"                      # 去掉桥接模式
# Create_Ipv6_Lan="0"                     # 创建 IPv6 LAN
# echo "CONFIG_GATEWAY_SETTINGS=\"$Gateway_Settings\"" >> .config
# echo "CONFIG_DNS_SETTINGS=\"$DNS_Settings\"" >> .config
# echo "CONFIG_BROADCAST_IPV4=\"$Broadcast_Ipv4\"" >> .config
# echo "CONFIG_DISABLE_DHCP=\"$Disable_DHCP\"" >> .config
# # echo "CONFIG_DISABLE_BRIDGE=\"$Disable_Bridge\"" >> .config
echo "CONFIG_CREATE_IPV6_LAN=\"$Create_Ipv6_Lan\"" >> .config
# cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
# [ "$Gateway_Settings" != "0" ] && uci set network.lan.gateway='$Gateway_Settings'
# [ "$DNS_Settings" != "0" ] && uci set network.lan.dns='$DNS_Settings'
# [ "$Disable_DHCP" = "1" ] && uci set dhcp.lan.ignore='1'
# [ "$Disable_Bridge" = "1" ] && uci delete network.lan.type
# uci commit
# EOF

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

# unzip
rm -rf feeds/packages/utils/unzip
git clone https://github.com/sbwml/feeds_packages_utils_unzip feeds/packages/utils/unzip

# golang 1.23
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# luci-app-filemanager
rm -rf feeds/luci/applications/luci-app-filemanager
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager


# nghttp3
# rm -rf feeds/packages/libs/nghttp3
# git clone https://github.com/sbwml/package_libs_nghttp3 feeds/packages/libs/nghttp3

# ngtcp2
# rm -rf feeds/packages/libs/ngtcp2
# git clone https://github.com/sbwml/package_libs_ngtcp2 feeds/packages/libs/ngtcp2

# curl
# rm -rf feeds/packages/net/curl
# git clone https://github.com/sbwml/feeds_packages_net_curl feeds/packages/net/curl

# 替换curl修改版（无nghttp3、ngtcp2）
curl_ver=$(cat feeds/packages/net/curl/Makefile | grep -i "PKG_VERSION:=" | awk 'BEGIN{FS="="};{print $2}')
[ "$(check_ver "$curl_ver" "8.12.0")" != "0" ] && {
	echo "替换curl版本"
	rm -rf feeds/packages/net/curl
	cp -rf ${GITHUB_WORKSPACE}/patch/curl feeds/packages/net/curl
}

# apk-tools APK管理器不再校验版本号的合法性
mkdir -p package/system/apk/patches && cp -f ${GITHUB_WORKSPACE}/patch/apk-tools/9999-hack-for-linux-pre-releases.patch package/system/apk/patches/

mirror=raw.githubusercontent.com/sbwml/r4s_build_script/master

# 防火墙4添加自定义nft命令支持
# curl -s https://$mirror/openwrt/patch/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch | patch -p1
patch -p1 < ${GITHUB_WORKSPACE}/patch/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch

pushd feeds/luci
	# 防火墙4添加自定义nft命令选项卡
	# curl -s https://$mirror/openwrt/patch/firewall4/luci-24.10/0004-luci-add-firewall-add-custom-nft-rule-support.patch | patch -p1
	patch -p1 < ${GITHUB_WORKSPACE}/patch/firewall4/0004-luci-add-firewall-add-custom-nft-rule-support.patch
	# 状态-防火墙页面去掉iptables警告，并添加nftables、iptables标签页
	# curl -s https://$mirror/openwrt/patch/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch | patch -p1
	patch -p1 < ${GITHUB_WORKSPACE}/patch/firewall4/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch
popd

# 补充 firewall4 luci 中文翻译
cat >> "feeds/luci/applications/luci-app-firewall/po/zh_Hans/firewall.po" <<-EOF
	
	msgid ""
	"Custom rules allow you to execute arbitrary nft commands which are not "
	"otherwise covered by the firewall framework. The rules are executed after "
	"each firewall restart, right after the default ruleset has been loaded."
	msgstr ""
	"自定义规则允许您执行不属于防火墙框架的任意 nft 命令。每次重启防火墙时，"
	"这些规则在默认的规则运行后立即执行。"
	
	msgid ""
	"Applicable to internet environments where the router is not assigned an IPv6 prefix, "
	"such as when using an upstream optical modem for dial-up."
	msgstr ""
	"适用于路由器未分配 IPv6 前缀的互联网环境，例如上游使用光猫拨号时。"

	msgid "NFtables Firewall"
	msgstr "NFtables 防火墙"

	msgid "IPtables Firewall"
	msgstr "IPtables 防火墙"
EOF

# 精简 UPnP 菜单名称
sed -i 's#\"title\": \"UPnP IGD \& PCP\"#\"title\": \"UPnP\"#g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
# 移动 UPnP 到 “网络” 子菜单
sed -i 's/services/network/g' feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json

# rpcd - fix timeout
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

# vim - fix E1187: Failed to source defaults.vim
pushd feeds/packages
	vim_ver=$(cat utils/vim/Makefile | grep -i "PKG_VERSION:=" | awk 'BEGIN{FS="="};{print $2}' | awk 'BEGIN{FS=".";OFS="."};{print $1,$2}')
	[ "$vim_ver" = "9.0" ] && {
		echo "修复 vim E1187 的错误"
		# curl -s https://github.com/openwrt/packages/commit/699d3fbee266b676e21b7ed310471c0ed74012c9.patch | patch -p1
		patch -p1 < ${GITHUB_WORKSPACE}/patch/vim/0001-vim-fix-renamed-defaults-config-file.patch
	}
popd

# 修正部分从第三方仓库拉取的软件 Makefile 路径问题
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

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
Ttyd_account_free_login="1"             # ttyd 免密登录
Delete_unnecessary_items="1"            # 删除多余固件
Disable_53_redirection="1"              # 删除 DNS 53 重定向
Cancel_running="1"                      # 取消跑分任务
echo "CONFIG_TTYD_ACCOUNT_FREE_LOGIN=\"$Ttyd_account_free_login\"" >> .config
echo "CONFIG_DELETE_UNNECESSARY_ITEMS=\"$Delete_unnecessary_items\"" >> .config
echo "CONFIG_DISABLE_53_REDIRECTION=\"$Disable_53_redirection\"" >> .config
echo "CONFIG_CANCEL_RUNNING=\"$Cancel_running\"" >> .config
[ "$Ttyd_account_free_login" = "1" ] && \
    cat << EOF >> package/base-files/files/etc/uci-defaults/99-custom-settings
uci set ttyd.@ttyd[0].command='/bin/sh -l'
uci commit ttyd
EOF


# 修改插件名字
[ -d package ] && find package/ -type f -exec sed -i 's/"终端"/"终端TTYD"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"网络存储"/"NAS"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"实时流量监测"/"流量"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"KMS 服务器"/"KMS激活"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"USB 打印服务器"/"打印服务"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"Web 管理"/"Web管理"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"管理权"/"管理权"/g' {} +
[ -d package ] && find package/ -type f -exec sed -i 's/"带宽监控"/"带宽监控"/g' {} +

# 自定义默认配置
sed -i '/exit 0$/d' package/emortal/default-settings/files/99-default-settings
cat ${GITHUB_WORKSPACE}/immortalwrt/default-settings >> package/emortal/default-settings/files/99-default-settings

# 拷贝自定义文件
if [ -n "$(ls -A "${GITHUB_WORKSPACE}/immortalwrt/diy" 2>/dev/null)" ]; then
	cp -Rf ${GITHUB_WORKSPACE}/immortalwrt/diy/* .
fi

#./scripts/feeds update -a
#./scripts/feeds install -a

make defconfig

echo "========================="
echo " DIY2 配置完成……"