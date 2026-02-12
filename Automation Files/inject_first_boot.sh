#!/bin/bash
set -e
# =================================================
# USAGE CHECK
# =================================================
if [ $# -ne 1 ]; then
    echo "Usage: sudo ./inject_first_boot.sh /dev/sdX"
    exit 1
fi
DISK="$1"
BASE_DIR="$(pwd)"
SCRIPTS_SRC="$BASE_DIR/scripts"
SERVICE_SRC="$BASE_DIR/first-boot.service"
ROOT_MNT="/mnt/rpi-root"
BOOT_MNT="/mnt/rpi-boot"
# =================================================
# VALIDATION
# =================================================
if [ ! -b "$DISK" ]; then
    echo "[ERROR] $DISK is not a valid block device"
    exit 1
fi
if [ ! -f "$SERVICE_SRC" ]; then
    echo "[ERROR] first-boot.service not found"
    exit 1
fi
if [ ! -f "$SCRIPTS_SRC/first_boot_setup.sh" ]; then
    echo "[ERROR] first_boot_setup.sh not found in scripts/"
    exit 1
fi
# =================================================
# CLEAN PREVIOUS MOUNTS
# =================================================
umount "${DISK}1" 2>/dev/null || true
umount "${DISK}2" 2>/dev/null || true
umount "$ROOT_MNT" 2>/dev/null || true
umount "$BOOT_MNT" 2>/dev/null || true
# =================================================
# MOUNT PARTITIONS
# =================================================
echo "[INFO] Mounting partitions"
mkdir -p "$ROOT_MNT" "$BOOT_MNT"
mount "${DISK}2" "$ROOT_MNT"
mount "${DISK}1" "$BOOT_MNT"
# =================================================
# READ RUTOMATRIX USER (SOURCE OF TRUTH)
# =================================================
if [ ! -f "$BOOT_MNT/rutomatrix_user" ]; then
    echo "[ERROR] rutomatrix_user file not found in boot partition"
    umount "$BOOT_MNT"
    umount "$ROOT_MNT"
    exit 1
fi
USERNAME="$(cat "$BOOT_MNT/rutomatrix_user")"
USER_HOME="$ROOT_MNT/home/$USERNAME"
echo "[INFO] Detected Rutomatrix user: $USERNAME"
# =================================================
# CREATE SCRIPTS DIRECTORY
# =================================================
mkdir -p "$USER_HOME"
mkdir -p "$USER_HOME/scripts"
# =================================================
# COPY FIRST BOOT SCRIPTS
# =================================================
echo "[INFO] Copying first boot scripts"
cp "$SCRIPTS_SRC/first_boot_setup.sh" "$USER_HOME/scripts/"
cp "$SCRIPTS_SRC/verify_provisioning.sh" "$USER_HOME/scripts/"
chmod +x "$USER_HOME/scripts/"*.sh
# =================================================
# INSTALL SYSTEMD SERVICE
# =================================================
echo "[INFO] Installing first-boot.service"
mkdir -p "$ROOT_MNT/etc/systemd/system"
cp "$SERVICE_SRC" "$ROOT_MNT/etc/systemd/system/first-boot.service"
mkdir -p "$ROOT_MNT/etc/systemd/system/multi-user.target.wants"
ln -sf \
  /etc/systemd/system/first-boot.service \
  "$ROOT_MNT/etc/systemd/system/multi-user.target.wants/first-boot.service"
# =================================================
# FIX OWNERSHIP (NUMERIC UID SAFE)
# =================================================
chown -R 1000:1000 "$USER_HOME"
# =================================================
# CLEANUP
# =================================================
sync
umount "$BOOT_MNT"
umount "$ROOT_MNT"
echo "[DONE] First boot provisioning injected successfully"
echo "[DONE] User: $USERNAME"