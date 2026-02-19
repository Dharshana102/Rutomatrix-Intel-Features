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
# Folder where postcode logs will be stored
LOGDIR="$BASE_DIR/postcode_logs"

# Serial configuration
PORT="/dev/ttyAMA0"
BAUDRATE="115200"

# Create the folder if it doesn't exist
mkdir -p "$LOGDIR"

# Create filename with date & time
LOGFILE="$LOGDIR/POSTCODE_LOG_$(date +%d-%m-%y-%H-%M).txt"

echo "---------------------------------------------------"
echo "Postcode serial logging started..."
echo "Port    : $PORT"
echo "Baud    : $BAUDRATE"
echo "Log file: $LOGFILE"
echo "---------------------------------------------------"

# Start minicom and capture logs
# -C : capture file
sudo minicom -b "$BAUDRATE" -o -D "$PORT" -C "$LOGFILE"
