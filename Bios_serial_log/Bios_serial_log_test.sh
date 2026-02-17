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
# Folder where logs will be stored
# Create the folder if it doesnâ€™t exist
mkdir -p "$LOGDIR"

# Create filename with date & time
LOGFILE="$LOGDIR/BIOS_LOG_$(date +%d-%m-%y-%H-%M).txt"

echo "---------------------------------------------------"
echo "Serial logging started..."
echo "Port    : /dev/ttyUSB0"
echo "Baud    : 115200"
echo "Log file: $LOGFILE"
echo "---------------------------------------------------"

# Run picocom and log output
#picocom -b 115200 /dev/ttyUSB0 | tee "$LOGFILE"

picocom -b 115200 --nolock /dev/ttyUSB0 | tee "$LOGFILE"
