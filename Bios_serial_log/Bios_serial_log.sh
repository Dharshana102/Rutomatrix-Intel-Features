#!/bin/bash
# -------------------------------------------------
# Detect Rutomatrix username dynamically
# -------------------------------------------------
if [ -f /boot/firmware/rutomatrix_user ]; then
    USERNAME=$(cat /boot/firmware/rutomatrix_user)
elif [ -f /boot/rutomatrix_user ]; then
    USERNAME=$(cat /boot/rutomatrix_user)
else
    USERNAME=$(ls -1 /home | grep -v root | head -n1)
fi
 
if [ -z "$USERNAME" ]; then
    echo "ERROR: Could not detect Rutomatrix user"
    exit 1
fi
 
BASE_DIR="/home/$USERNAME"
LOGDIR="$BASE_DIR/serial_logs" 
 
# Create log folder
mkdir -p "$LOGDIR"
chmod 755 "$LOGDIR"
 
LOGFILE="$LOGDIR/BIOS_LOG_$(date +%d-%m-%y-%H-%M).txt"
 
echo "---------------------------------------------------"
echo "Serial logging started..."
echo "Port    : /dev/ttyUSB0"
echo "Baud    : 115200"
echo "Log file: $LOGFILE"
echo "---------------------------------------------------"
 
# Set baud rate (important!)
stty -F /dev/ttyUSB0 115200 raw -echo
 
# Read serial data and log it (works in systemd & Flask)
stdbuf -oL cat /dev/ttyUSB0 | tee "$LOGFILE"
