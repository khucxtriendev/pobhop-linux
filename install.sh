#!/usr/bin/env bash
# ==============================================================================
# PodHop - Trình cài đặt tự động cho Linux
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="${HOME}"

echo "=========================================================="
echo "    Cài đặt PodHop - Apple AirPods Ecosystem for Linux    "
echo "=========================================================="

# 1. Kiểm tra quyền sudo
if [ "$EUID" -ne 0 ]; then
    echo "[-] Vui lòng chạy lệnh cài đặt với sudo: sudo ./install.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_UID=$(id -u "$REAL_USER")
REAL_GID=$(id -g "$REAL_USER")
REAL_HOME=$(eval echo "~$REAL_USER")

echo "[+] Người dùng mục tiêu: $REAL_USER (UID: $REAL_UID, Home: $REAL_HOME)"

# 2. Kiểm tra các gói hệ thống cần thiết
echo "[+] Kiểm tra các gói phụ thuộc..."
MISSING_PKGS=()
for cmd in python3 playerctl notify-send pactl busctl; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_PKGS+=("$cmd")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "[!] Cảnh báo: Thiếu các tiện ích sau: ${MISSING_PKGS[*]}"
    echo "    Vui lòng cài đặt trước (VD: pacman -S playerctl libnotify pipewire python-pyside6 hoặc apt install playerctl libnotify-bin pulseaudio-utils python3-pyside6)"
fi

# 3. Tạo thư mục đích /opt/podhop
echo "[+] Sao chép mã nguồn ứng dụng vào /opt/podhop..."
mkdir -p /opt/podhop/icons
cp -f "$SCRIPT_DIR/bin/airpods" /opt/podhop/podhop_gui.py
cp -f "$SCRIPT_DIR/bin/podhop-daemon" /opt/podhop/podhop_daemon.py
cp -r -f "$SCRIPT_DIR/icons/"* /opt/podhop/icons/
cp -f "$SCRIPT_DIR/icons/airpods.png" /opt/podhop/airpods.png
cp -f "$SCRIPT_DIR/icons/airpods.svg" /opt/podhop/airpods.svg

chmod +x /opt/podhop/podhop_gui.py
chmod +x /opt/podhop/podhop_daemon.py

# 4. Cài đặt các binary vào /usr/local/bin
echo "[+] Cài đặt các lệnh thực thi /usr/local/bin/airpods và podhop-daemon..."
ln -sf /opt/podhop/podhop_gui.py /usr/local/bin/airpods
cp -f "$SCRIPT_DIR/bin/podhop-daemon" /usr/local/bin/podhop-daemon
chmod +x /usr/local/bin/podhop-daemon

# 5. Cài đặt Icons vào hệ thống
echo "[+] Cài đặt biểu tượng ứng dụng (App Icons)..."
for size in 32 48 64 128 256 512; do
    TARGET_DIR="/usr/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$TARGET_DIR"
    cp -f "$SCRIPT_DIR/icons/airpods.png" "$TARGET_DIR/airpods.png" 2>/dev/null || true
done
mkdir -p /usr/share/icons/hicolor/scalable/apps
cp -f "$SCRIPT_DIR/icons/airpods.svg" /usr/share/icons/hicolor/scalable/apps/airpods.svg 2>/dev/null || true

# 6. Cài đặt file .desktop
echo "[+] Cài đặt menu ứng dụng (Desktop Entry)..."
mkdir -p /usr/share/applications
cp -f "$SCRIPT_DIR/desktop/airpods.desktop" /usr/share/applications/airpods.desktop
chmod 644 /usr/share/applications/airpods.desktop

# 7. Cài đặt Systemd User Service
echo "[+] Cài đặt tiến trình nền chạy ngầm (Systemd User Service)..."
USER_SYSTEMD_DIR="$REAL_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"
cp -f "$SCRIPT_DIR/systemd/podhop.service" "$USER_SYSTEMD_DIR/podhop.service"
chown -R "$REAL_UID:$REAL_GID" "$REAL_HOME/.config/systemd"

# Kích hoạt service cho user
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user daemon-reload || true
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user enable podhop.service || true
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$REAL_UID/bus" systemctl --user restart podhop.service || true

# 8. Cập nhật cache giao diện
which update-desktop-database &>/dev/null && update-desktop-database -q /usr/share/applications || true
which gtk-update-icon-cache &>/dev/null && gtk-update-icon-cache -q /usr/share/icons/hicolor || true

echo ""
echo "=========================================================="
echo "    CÀI ĐẶT THÀNH CÔNG PODHOP!"
echo "    - Mở ứng dụng bằng lệnh: airpods"
echo "    - Tìm 'AirPods 4 ANC Manager' trong Menu ứng dụng"
echo "    - Daemon chạy ngầm quản lý âm thanh đã được kích hoạt."
echo "=========================================================="
