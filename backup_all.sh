#!/bin/sh

# 备份时间戳
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/root/glinet_backups"
BACKUP_NAME="glinet_backup_$DATE.tar.gz"

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 获取系统默认软件包列表
opkg list-installed | cut -f1 -d' ' | sort > "$BACKUP_DIR/default_packages.txt"
# 获取当前系统软件包
opkg list-installed | cut -f1 -d' ' | sort > "$BACKUP_DIR/current_packages.txt"

# 获取单独安装的软件包（差集）
if command -v comm >/dev/null 2>&1; then
    comm -13 "$BACKUP_DIR/default_packages.txt" "$BACKUP_DIR/current_packages.txt" > "$BACKUP_DIR/custom_packages.txt"
else
    grep -Fxvf "$BACKUP_DIR/default_packages.txt" "$BACKUP_DIR/current_packages.txt" > "$BACKUP_DIR/custom_packages.txt"
fi

# 备份配置文件
mkdir -p "$BACKUP_DIR/configs"
cp -a /etc/config "$BACKUP_DIR/configs/"
cp -a /etc/firewall.user "$BACKUP_DIR/configs/" 2>/dev/null
cp -a /etc/rc.local "$BACKUP_DIR/configs/" 2>/dev/null

# 备份opkg相关配置（新增/etc/opkg.conf）
mkdir -p "$BACKUP_DIR/opkg_sources"
cp -a /etc/opkg.conf "$BACKUP_DIR/opkg_sources/" 2>/dev/null
cp -a /etc/opkg/customfeeds.conf "$BACKUP_DIR/opkg_sources/" 2>/dev/null
cp -a /etc/opkg/distfeeds.conf "$BACKUP_DIR/opkg_sources/" 2>/dev/null

# 打包所有内容
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME" custom_packages.txt configs/ opkg_sources/

# 输出备份路径
echo "备份完成：$BACKUP_DIR/$BACKUP_NAME"

# 清理中间文件（可选）
rm -rf "$BACKUP_DIR/configs" "$BACKUP_DIR/opkg_sources" "$BACKUP_DIR/default_packages.txt" "$BACKUP_DIR/current_packages.txt"
