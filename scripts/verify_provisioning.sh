#!/bin/bash
 
REPORT="/home/rpi/provision_verification_report.txt"
BASE="/home/rpi"
MARKER="$BASE/.first_boot_done"
 
exec > "$REPORT" 2>&1
 
echo "====================================================="
echo " RUTOMATRIX PROVISIONING VERIFICATION REPORT"
echo " Generated on: $(date)"
echo "====================================================="
echo
 
# -----------------------------------------------------
# Helper functions
# -----------------------------------------------------
check_exists() {
    if [ -e "$1" ]; then
        echo "[OK] Exists: $1"
    else
        echo "[FAIL] Missing: $1"
    fi
}
 
check_dir() {
    if [ -d "$1" ]; then
        echo "[OK] Directory: $1"
    else
        echo "[FAIL] Directory missing: $1"
    fi
}
 
check_file() {
    if [ -f "$1" ]; then
        echo "[OK] File: $1"
    else
        echo "[FAIL] File missing: $1"
    fi
}
 
check_exec() {
    if [ -x "$1" ]; then
        echo "[OK] Executable: $1"
    else
        echo "[FAIL] Not executable: $1"
    fi
}
 
check_service() {
    local svc="$1"
    echo "Service: $svc"
    if systemctl list-unit-files | grep -q "^$svc"; then
        echo "  [OK] Installed"
    else
        echo "  [FAIL] Not installed"
        return
    fi
 
    systemctl is-enabled "$svc" &>/dev/null \
&& echo "  [OK] Enabled" \
        || echo "  [FAIL] Not enabled"
 
    systemctl is-active "$svc" &>/dev/null \
&& echo "  [OK] Active" \
        || echo "  [WARN] Not running"
}
 
check_venv() {
    local dir="$1"
    echo "Virtualenv: $dir"
    check_dir "$dir/venv"
    check_exec "$dir/venv/bin/python"
}
 
# -----------------------------------------------------
# Global checks
# -----------------------------------------------------
echo "---- GLOBAL CHECKS ----"
check_file "$MARKER"
python3 --version
pip3 --version
check_exec "/usr/local/bin/ustreamer"
echo
 
# -----------------------------------------------------
# Feature directories
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
)
 
echo "---- FEATURE DIRECTORY CHECKS ----"
for f in "${FEATURES[@]}"; do
    check_dir "$BASE/$f"
done
echo
 
# -----------------------------------------------------
# Virtualenv checks
# -----------------------------------------------------
echo "---- PYTHON VENV CHECKS ----"
for f in "${FEATURES[@]}"; do
    check_venv "$BASE/$f"
done
echo
 
# -----------------------------------------------------
# Key file checks
# -----------------------------------------------------
echo "---- KEY FILE CHECKS ----"
 
check_file "$BASE/Streaming_HID/app.py"
check_file "$BASE/Postcode/app.py"
check_exec "$BASE/Postcode/postcode_serial_log.sh"
check_file "$BASE/Bios_serial_log/app.py"
check_exec "$BASE/Bios_serial_log/Bios_serial_log.sh"
check_file "$BASE/PDU/app.py"
check_file "$BASE/OS_Flashing/app.py"
check_file "$BASE/Firmware/app1.py"
 
echo
 
# -----------------------------------------------------
# Systemd services
# -----------------------------------------------------
echo "---- SYSTEMD SERVICE CHECKS ----"
check_service "streaming_hid.service"
check_service "composite-gadget.service"
check_service "usb_mass_storage.service"
check_service "postcode.service"
check_service "intel_ui_template.service"
echo
 
# -----------------------------------------------------
# Ownership check
# -----------------------------------------------------
echo "---- OWNERSHIP CHECK (rpi user) ----"
for f in "${FEATURES[@]}"; do
    owner=$(stat -c "%U" "$BASE/$f" 2>/dev/null)
    if [ "$owner" = "rpi" ]; then
        echo "[OK] Owner rpi: $BASE/$f"
    else
        echo "[WARN] Owner not rpi ($owner): $BASE/$f"
    fi
done
echo
 
echo "====================================================="
echo " VERIFICATION COMPLETED"
echo "====================================================="
