#!/bin/bash
 
# =================================================
# DYNAMIC USER DETECTION (Rutomatrix method)
# =================================================
 
if [ -f /boot/firmware/rutomatrix_user ]; then
    USERNAME=$(cat /boot/firmware/rutomatrix_user)
elif [ -f /boot/rutomatrix_user ]; then
    USERNAME=$(cat /boot/rutomatrix_user)
else
    USERNAME=$(ls -1 /home | grep -v root | head -n1)
fi
 
if [ -z "$USERNAME" ]; then
    echo "[ERROR] No user detected"
    exit 1
fi
 
BASE="/home/$USERNAME"
REPORT="$BASE/provision_verification_report.txt"
MARKER="$BASE/.first_boot_done"
LOGFILE="$BASE/first_boot.log"
 
exec > "$REPORT" 2>&1
 
echo "====================================================="
echo " RUTOMATRIX PROVISIONING VERIFICATION REPORT"
echo " Generated on: $(date)"
echo " User: $USERNAME"
echo "====================================================="
echo
 
# -----------------------------------------------------
# Helper functions
# -----------------------------------------------------
 
check_file() { [ -f "$1" ] && echo "[OK] File: $1" || echo "[FAIL] Missing file: $1"; }
check_dir() { [ -d "$1" ] && echo "[OK] Directory: $1" || echo "[FAIL] Missing directory: $1"; }
check_exec() { [ -x "$1" ] && echo "[OK] Executable: $1" || echo "[FAIL] Not executable: $1"; }
 
check_service() {
    local svc="$1"
    echo "Service: $svc"
 
    systemctl list-unit-files | grep -q "^$svc" \
&& echo "  [OK] Installed" \
        || { echo "  [FAIL] Not installed"; return; }
 
    systemctl is-enabled "$svc" &>/dev/null \
&& echo "  [OK] Enabled" \
        || echo "  [FAIL] Not enabled"
 
    systemctl is-active "$svc" &>/dev/null \
&& echo "  [OK] Active" \
        || echo "  [WARN] Not running"
}
 
check_venv() {
    local dir="$1"
    check_dir "$dir/venv"
    check_exec "$dir/venv/bin/python"
}
 
# -----------------------------------------------------
# GLOBAL CHECKS
# -----------------------------------------------------
 
echo "---- GLOBAL CHECKS ----"
check_file "$MARKER"
check_file "$LOGFILE"
python3 --version
pip3 --version
check_exec "/usr/local/bin/ustreamer"
flashrom --version &>/dev/null && echo "[OK] flashrom installed" || echo "[WARN] flashrom not installed"
echo
 
# -----------------------------------------------------
# FEATURE DIRECTORIES
# -----------------------------------------------------
 
FEATURES=(
"Streaming_HID"
"Postcode"
"intel_UI_templates"
"USB File Sharing"
"System_Atx"
"OS_Flashing"
"Firmware"
"Bios_serial_log"
"PDU"
"os"
"gadgets"
)
 
echo "---- FEATURE DIRECTORY CHECKS ----"
for f in "${FEATURES[@]}"; do
    check_dir "$BASE/$f"
done
echo
 
# -----------------------------------------------------
# PYTHON VENV CHECKS
# -----------------------------------------------------
 
echo "---- PYTHON VENV CHECKS ----"
for f in "${FEATURES[@]}"; do
    [ "$f" != "gadgets" ] && check_venv "$BASE/$f"
done
echo
 
# -----------------------------------------------------
# SYSTEMD SERVICE CHECKS
# -----------------------------------------------------
 
echo "---- SYSTEMD SERVICE CHECKS ----"
check_service "streaming_hid.service"
check_service "composite-gadget.service"
check_service "usb_mass_storage.service"
check_service "postcode.service"
check_service "intel_ui_template.service"
echo
 
# -----------------------------------------------------
# UART CHECK
# -----------------------------------------------------
 
echo "---- UART CONFIG CHECK ----"
CONFIG="/boot/firmware/config.txt"
grep -q "^enable_uart=1" "$CONFIG" && echo "[OK] enable_uart=1" || echo "[FAIL] enable_uart missing"
grep -q "^dtoverlay=uart1" "$CONFIG" && echo "[OK] dtoverlay=uart1" || echo "[FAIL] uart1 overlay missing"
grep -q "^dtoverlay=disable-bt" "$CONFIG" && echo "[OK] disable-bt set" || echo "[FAIL] disable-bt missing"
 
systemctl is-enabled serial-getty@ttyAMA0.service &>/dev/null \
&& echo "[WARN] serial-getty still enabled" \
    || echo "[OK] serial-getty disabled"
echo
 
# -----------------------------------------------------
# SPI CHECK
# -----------------------------------------------------
 
echo "---- SPI CONFIG CHECK ----"
grep -q "^dtparam=spi=on" "$CONFIG" && echo "[OK] SPI enabled in config.txt" || echo "[FAIL] SPI not enabled"
grep -q "^spi-dev" /etc/modules-load.d/raspberrypi.conf \
&& echo "[OK] spi-dev module present" \
    || echo "[FAIL] spi-dev module missing"
echo
 
# -----------------------------------------------------
# RC.LOCAL CHECK (SYSTEM ATX)
# -----------------------------------------------------
 
echo "---- SYSTEM ATX (rc.local) CHECK ----"
if grep -q "raspi-gpio set 20" /etc/rc.local; then
    echo "[OK] GPIO 20 config present"
else
    echo "[FAIL] GPIO 20 config missing"
fi
 
if grep -q "i2cset -y 1 0x72 2" /etc/rc.local; then
    echo "[OK] I2C ATX command present"
else
    echo "[FAIL] I2C ATX command missing"
fi
echo
 
# -----------------------------------------------------
# OWNERSHIP CHECK
# -----------------------------------------------------
 
echo "---- OWNERSHIP CHECK ($USERNAME) ----"
for f in "${FEATURES[@]}"; do
    owner=$(stat -c "%U" "$BASE/$f" 2>/dev/null)
    if [ "$owner" = "$USERNAME" ]; then
        echo "[OK] Owner correct: $BASE/$f"
    else
        echo "[WARN] Owner incorrect ($owner): $BASE/$f"
    fi
done
echo
 
echo "====================================================="
echo " VERIFICATION COMPLETED"
echo "====================================================="
