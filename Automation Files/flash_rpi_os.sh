#!/bin/bash
set -e
# =================================================
# USAGE CHECK
# =================================================
if [ $# -ne 1 ]; then
    echo "Usage: sudo ./flash_rpi_os.sh /dev/sdX"
    exit 1
fi
DISK="$1"
# =================================================
# PATHS
# =================================================
BASE_DIR="$(pwd)"
IMAGE_DIR="$BASE_DIR/rpi_images"
IMAGE_FILE="$(ls "$IMAGE_DIR"/*.img.xz | head -n1)"
STATE_FILE="$BASE_DIR/.rm_device_counter"
BOOT_MNT="/mnt/rpi-boot"
ROOT_MNT="/mnt/rpi-root"
HOSTNAME="Rutomatrix"
PASSWORD="rutomatrix"
# =================================================
# VALIDATION
# =================================================
if [ ! -b "$DISK" ]; then
    echo "[ERROR] $DISK is not a valid block device"
    exit 1
fi
if [ ! -f "$IMAGE_FILE" ]; then
    echo "[ERROR] No .img.xz found in rpi_images/"
    exit 1
fi
# =================================================
# AUTO-INCREMENT USERNAME (LOWERCASE ONLY)
# =================================================
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi
COUNT=$(cat "$STATE_FILE")
USERNAME=$(printf "rm%03d" "$COUNT")
NEXT_COUNT=$((COUNT + 1))
echo "$NEXT_COUNT" > "$STATE_FILE"
echo "[INFO] Flashing OS"
echo "[INFO] Target disk : $DISK"
echo "[INFO] Username    : $USERNAME"
echo "[INFO] Hostname    : $HOSTNAME"
# =================================================
# FLASH IMAGE
# =================================================
echo "[INFO] Writing image to disk (this will take time)..."
xzcat "$IMAGE_FILE" | dd of="$DISK" bs=4M status=progress conv=fsync
sync
sleep 3
# =================================================
# MOUNT PARTITIONS
# =================================================
mkdir -p "$BOOT_MNT" "$ROOT_MNT"
mount "${DISK}1" "$BOOT_MNT"
mount "${DISK}2" "$ROOT_MNT"
# =================================================
# ENABLE SSH
# =================================================
touch "$BOOT_MNT/ssh"
# =================================================
# STORE USERNAME FOR FIRST BOOT SCRIPT
# =================================================
echo "$USERNAME" > "$BOOT_MNT/rutomatrix_user"
# =================================================
# SET HOSTNAME
# =================================================
echo "$HOSTNAME" > "$ROOT_MNT/etc/hostname"
sed -i "s/127.0.1.1.*/127.0.1.1\t$HOSTNAME/" \
    "$ROOT_MNT/etc/hosts"
# =================================================
# CREATE USER (BOOKWORM METHOD)
# =================================================
PASSWORD_HASH=$(openssl passwd -6 "$PASSWORD")
cat <<EOF > "$BOOT_MNT/userconf"
$USERNAME:$PASSWORD_HASH
EOF
# =================================================
# CLEANUP
# =================================================
sync
umount "$BOOT_MNT"
umount "$ROOT_MNT"
echo "[DONE] OS flashed successfully"
echo "[DONE] User     : $USERNAME"
echo "[DONE] Hostname : $HOSTNAME"