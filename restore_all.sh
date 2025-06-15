#!/bin/sh

# -------------------- 参数设置 --------------------
BACKUP_DIR="/root/glinet_backups"
BACKUP_TARBALL=$(ls -t $BACKUP_DIR/glinet_backup_*.tar.gz 2>/dev/null | head -n 1)

# 如果找不到备份文件，则退出
if [ ! -f "$BACKUP_TARBALL" ]; then
  echo "❌ 未找到备份文件，请将 glinet_backup_xxx.tar.gz 放到 $BACKUP_DIR 目录下"
  exit 1
fi

# -------------------- 联网检测函数 --------------------
check_network() {
  echo "🌐 正在检测网络连接..."
  for i in $(seq 1 10); do
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
      echo "✅ 网络已连接"
      return 0
    fi
    echo "🔁 等待联网中 ($i/10)..."
    sleep 5
  done
  echo "❌ 无法连接互联网，退出"
  return 1
}

# -------------------- 解压备份 --------------------
prepare_backup() {
  echo "📦 解压备份文件：$BACKUP_TARBALL"
  mkdir -p /tmp/glinet_restore
  if ! tar -xzf "$BACKUP_TARBALL" -C /tmp/glinet_restore; then
    echo "❌ 解压失败，请检查备份文件完整性"
    exit 1
  fi
}

# -------------------- 恢复自定义源 --------------------
restore_feeds() {
  echo "🔧 恢复自定义 opkg 源"
  if [ -d /tmp/glinet_restore/opkg_sources ]; then
    cp -f /tmp/glinet_restore/opkg_sources/* /etc/opkg/
    [ -f /tmp/glinet_restore/opkg_sources/opkg.conf ] && \
      cp -f /tmp/glinet_restore/opkg_sources/opkg.conf /etc/
  fi
}

# -------------------- 安装未安装的软件包 --------------------
install_packages() {
  echo "📦 正在更新 opkg 软件包列表..."
  opkg update

  echo "📥 正在安装未安装的软件包..."
  if [ -f /tmp/glinet_restore/custom_packages.txt ]; then
    while read -r pkg; do
      if [ -z "$pkg" ]; then
        continue
      fi
      if opkg status "$pkg" >/dev/null 2>&1; then
        echo "✔️ 已安装：$pkg"
      else
        echo "➕ 安装：$pkg"
        opkg install "$pkg" --force-depends || echo "⚠️ 安装失败：$pkg"
      fi
    done < /tmp/glinet_restore/custom_packages.txt
  else
    echo "⚠️ 未找到 custom_packages.txt，跳过插件安装"
  fi
}

# -------------------- 恢复配置文件 --------------------
restore_configs() {
  echo "⚙️ 正在恢复配置文件..."
  mkdir -p /etc/config_backup
  cp -af /etc/config/* /etc/config_backup/ 2>/dev/null
  if [ -d /tmp/glinet_restore/configs ]; then
    cp -af /tmp/glinet_restore/configs/* /etc/config/
  fi
  [ -f /tmp/glinet_restore/firewall.user ] && cp -f /tmp/glinet_restore/firewall.user /etc/
  [ -f /tmp/glinet_restore/rc.local ] && cp -f /tmp/glinet_restore/rc.local /etc/
}

# -------------------- 重启提示 --------------------
final_step() {
  echo ""
  echo "✅ 配置与插件恢复完成，建议执行以下命令重启系统："
  echo "reboot"
}

# -------------------- 主逻辑 --------------------
main() {
  check_network || exit 1
  prepare_backup
  restore_feeds
  install_packages
  restore_configs
  final_step
}

main
