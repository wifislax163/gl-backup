#!/bin/sh

# 1. 路径定义
DEFAULT_LIST="/root/default_packages.txt"
ALL_LIST="/root/all_packages.txt"
USER_LIST="/root/user_packages.txt"
CONFIG_BACKUP="/root/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
OPKG_BACKUP="/root/opkg_conf_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

# 2. 备份自带包列表（首次运行时自动生成）
if [ ! -f "$DEFAULT_LIST" ]; then
    echo "未检测到自带包列表，正在生成 $DEFAULT_LIST ..."
    opkg list-installed | awk '{print $1}' > "$DEFAULT_LIST"
    echo "自带包列表已保存。"
    echo "请在安装插件后再次运行本脚本以备份用户安装的包。"
    exit 0
fi

# 3. 备份当前所有包
opkg list-installed | awk '{print $1}' > "$ALL_LIST"

# 4. 过滤出用户安装的包
grep -v -f "$DEFAULT_LIST" "$ALL_LIST" > "$USER_LIST"
echo "用户安装的包已保存到 $USER_LIST"

# 5. 备份系统配置
tar czvf "$CONFIG_BACKUP" /etc/config
echo "系统配置已打包备份到 $CONFIG_BACKUP"

# 6. 备份opkg源配置和主配置
tar czvf "$OPKG_BACKUP" /etc/opkg/customfeeds.conf /etc/opkg/distfeeds.conf /etc/opkg.conf 2>/dev/null
if [ $? -eq 0 ]; then
    echo "opkg配置已打包备份到 $OPKG_BACKUP"
else
    echo "opkg配置文件不存在或部分不存在，未打包。"
fi

echo "全部备份完成！"
