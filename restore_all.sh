#!/bin/sh

# 1. 路径定义（请根据实际备份文件名修改）
USER_LIST="/root/user_packages.txt"
CONFIG_BACKUP=$(ls /root/config_backup_*.tar.gz 2>/dev/null | tail -n 1)
OPKG_BACKUP=$(ls /root/opkg_conf_backup_*.tar.gz 2>/dev/null | tail -n 1)

# 2. 检查包列表文件
if [ ! -f "$USER_LIST" ]; then
    echo "未找到 $USER_LIST，请先备份包列表！"
    exit 1
fi

# 3. 恢复opkg源配置
if [ -f "$OPKG_BACKUP" ]; then
    echo "正在恢复opkg源配置..."
    tar xzvf "$OPKG_BACKUP" -C /
else
    echo "未找到opkg源配置备份，跳过。"
fi

# 4. 联网检测
echo "正在检测网络连通性..."
ping -c 3 -W 2 223.5.5.5 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "无法连接到 223.5.5.5，请检查网络后重试！"
    exit 1
fi
echo "网络正常，开始更新软件源..."

# 5. 更新opkg源
opkg update

# 6. 恢复系统配置
if [ -f "$CONFIG_BACKUP" ]; then
    echo "正在恢复系统配置..."
    tar xzvf "$CONFIG_BACKUP" -C /
    echo "系统配置恢复完成。"
else
    echo "未找到系统配置备份，跳过。"
fi

# 7. 恢复用户安装包
echo "开始恢复安装用户插件..."
while read pkg; do
    if opkg list-installed | grep -q "^$pkg "; then
        echo "$pkg 已安装，跳过。"
    else
        echo "正在安装 $pkg ..."
        opkg install "$pkg"
    fi
done < "$USER_LIST"

echo "全部恢复完成！如有需要请重启路由器。"
