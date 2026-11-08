#!/usr/bin/env bash
# ==============================================================================
# PodHop - Trình gỡ cài đặt sạch sẽ cho Linux
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "[-] Vui lòng chạy lệnh gỡ cài đặt với sudo: sudo ./uninstall.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_HOME=$(eval echo "~$REAL_USER")

echo "=========================================================="
echo "    Gỡ cài đặt PodHop..."
echo "=========================================================="

# 1. Dừng và vô hiệu hóa service
echo "[+] Dừng tiến trình ngầm podhop.service..."
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user stop podhop.service 2>/dev/null || true
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user disable podhop.service 2>/dev/null || true

# 2. Xóa service file
rm -f "$REAL_HOME/.config/systemd/user/podhop.service"
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user daemon-reload 2>/dev/null || true

# 3. Xóa các binary và thư mục cài đặt
echo "[+] Xóa các file thực thi và thư mục cài đặt..."
rm -rf /opt/podhop
rm -f /usr/local/bin/airpods
rm -f /usr/local/bin/podhop-daemon

# 4. Xóa desktop entry và icons
echo "[+] Xóa desktop entry và icons..."
rm -f /usr/share/applications/airpods.desktop
rm -f "$REAL_HOME/.local/share/applications/airpods.desktop"

for size in 32 48 64 128 256 512; do
    rm -f "/usr/share/icons/hicolor/${size}x${size}/apps/airpods.png"
    rm -f "$REAL_HOME/.local/share/icons/hicolor/${size}x${size}/apps/airpods.png"
done
rm -f /usr/share/icons/hicolor/scalable/apps/airpods.svg
rm -f "$REAL_HOME/.local/share/icons/hicolor/scalable/apps/airpods.svg"

which update-desktop-database &>/dev/null && update-desktop-database -q /usr/share/applications || true
which gtk-update-icon-cache &>/dev/null && gtk-update-icon-cache -q /usr/share/icons/hicolor || true

echo "=========================================================="
echo "    Đã gỡ cài đặt hoàn tất sạch sẽ!"
echo "=========================================================="
