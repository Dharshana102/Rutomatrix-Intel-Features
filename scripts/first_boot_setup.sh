#!/bin/bash
set -e
 
# =================================================
# CONFIG
# =================================================
MARKER="/home/rpi/.first_boot_done"
LOG="/home/rpi/first_boot.log"
BASE_DIR="/home/rpi"
 
REPO_NAME="Rutomatrix-Intel-Features"
REPO_URL="https://github.com/Dharshana102/Rutomatrix-Intel-Features.git"
 
STREAMING_DIR="$BASE_DIR/Streaming_HID"
POSTCODE_DIR="$BASE_DIR/Postcode"
INTEL_UI_DIR="$BASE_DIR/intel_UI_templates"
USB_SHARE_DIR="$BASE_DIR/USB File Sharing"
SYSTEM_ATX_DIR="$BASE_DIR/System_Atx"
OS_FLASHING_DIR="$BASE_DIR/OS_Flashing"
FIRMWARE_DIR="$BASE_DIR/Firmware"
BIOS_SERIAL_DIR="$BASE_DIR/Bios_serial_log"
PDU_DIR="$BASE_DIR/PDU"
 
GADGETS_DIR="$BASE_DIR/gadgets"
USTREAMER_DIR="$STREAMING_DIR/ustreamer"
 
# =================================================
# EXIT IF ALREADY DONE
# =================================================
if [ -f "$MARKER" ]; then
    echo "[FIRST BOOT] Already completed. Exiting."
    exit 0
fi
 
exec > >(tee -a "$LOG") 2>&1
 
echo "======================================"
echo "[FIRST BOOT] Provisioning started"
echo "======================================"
 
# =================================================
# WAIT FOR NETWORK
# =================================================
until ping -c1 8.8.8.8 >/dev/null 2>&1; do sleep 2; done
 
# =================================================
# WAIT FOR APT LOCK
# =================================================
while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
      fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
      fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep 2
done
 
# =================================================
# SYSTEM PACKAGES
# =================================================
apt update
apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    git \
    usbutils \
    libusb-1.0-0 \
    libffi-dev \
    v4l-utils \
    ffmpeg \
    libjpeg-dev \
    libevent-dev \
    libbsd-dev \
    build-essential
 
# =================================================
# CLONE MAIN REPO
# =================================================
cd "$BASE_DIR"
rm -rf "$REPO_NAME"
git clone "$REPO_URL"
 
# =================================================
# DEPLOY FEATURES
# =================================================
rm -rf "$STREAMING_DIR" && cp -r "$BASE_DIR/$REPO_NAME/Streaming_HID" "$STREAMING_DIR"
rm -rf "$POSTCODE_DIR" && cp -r "$BASE_DIR/$REPO_NAME/Postcode" "$POSTCODE_DIR"
rm -rf "$INTEL_UI_DIR" && cp -r "$BASE_DIR/$REPO_NAME/intel_UI_templates" "$INTEL_UI_DIR"
rm -rf "$USB_SHARE_DIR" && cp -r "$BASE_DIR/$REPO_NAME/USB File Sharing" "$USB_SHARE_DIR"
rm -rf "$SYSTEM_ATX_DIR" && cp -r "$BASE_DIR/$REPO_NAME/System_Atx" "$SYSTEM_ATX_DIR"
rm -rf "$OS_FLASHING_DIR" && cp -r "$BASE_DIR/$REPO_NAME/OS_Flashing" "$OS_FLASHING_DIR"
rm -rf "$FIRMWARE_DIR" && cp -r "$BASE_DIR/$REPO_NAME/Firmware" "$FIRMWARE_DIR"
rm -rf "$BIOS_SERIAL_DIR" && cp -r "$BASE_DIR/$REPO_NAME/Bios_serial_log" "$BIOS_SERIAL_DIR"
rm -rf "$PDU_DIR" && cp -r "$BASE_DIR/$REPO_NAME/PDU" "$PDU_DIR"
 
# =================================================
# EXTRACT USB GADGETS
# =================================================
rm -rf "$GADGETS_DIR"
cp -r "$STREAMING_DIR/gadgets" "$GADGETS_DIR"
rm -rf "$STREAMING_DIR/gadgets"
chmod +x "$GADGETS_DIR"/*.sh
 
# =================================================
# PERMISSIONS
# =================================================
chmod +x "$USB_SHARE_DIR/usb_file_sharing.py"
chmod +x "$SYSTEM_ATX_DIR"/*.sh
chmod +x "$BIOS_SERIAL_DIR/Bios_serial_log.sh"
 
chown -R rpi:rpi \
    "$STREAMING_DIR" \
    "$POSTCODE_DIR" \
    "$INTEL_UI_DIR" \
    "$USB_SHARE_DIR" \
    "$SYSTEM_ATX_DIR" \
    "$OS_FLASHING_DIR" \
    "$FIRMWARE_DIR" \
    "$BIOS_SERIAL_DIR" \
    "$PDU_DIR" \
    "$GADGETS_DIR"
 
# =================================================
# PYTHON VIRTUAL ENVIRONMENTS
# =================================================
setup_venv () {
    cd "$1"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    [ -f requirements.txt ] && pip install -r requirements.txt
    deactivate
}
 
setup_venv "$STREAMING_DIR"
setup_venv "$POSTCODE_DIR"
setup_venv "$INTEL_UI_DIR"
setup_venv "$USB_SHARE_DIR"
setup_venv "$SYSTEM_ATX_DIR"
setup_venv "$OS_FLASHING_DIR"
setup_venv "$FIRMWARE_DIR"
setup_venv "$BIOS_SERIAL_DIR"
setup_venv "$PDU_DIR"
 
# =================================================
# INSTALL & BUILD uSTREAMER
# =================================================
if [ ! -d "$USTREAMER_DIR" ]; then
    cd "$STREAMING_DIR"
    git clone https://github.com/pikvm/ustreamer
fi
 
cd "$USTREAMER_DIR"
make
cp ustreamer /usr/local/bin/ustreamer
chmod +x /usr/local/bin/ustreamer
 
# =================================================
# INSTALL SYSTEMD SERVICES
# =================================================
cp "$STREAMING_DIR/streaming_hid.service" /etc/systemd/system/
cp "$STREAMING_DIR/composite-gadget.service" /etc/systemd/system/
cp "$OS_FLASHING_DIR/usb_mass_storage.service" /etc/systemd/system/ 2>/dev/null || true
cp "$INTEL_UI_DIR/intel_ui_template.service" /etc/systemd/system/ 2>/dev/null || true
cp "$POSTCODE_DIR/postcode.service" /etc/systemd/system/ 2>/dev/null || true
 
systemctl daemon-reexec
systemctl daemon-reload
 
systemctl enable composite-gadget.service
systemctl enable streaming_hid.service
systemctl enable usb_mass_storage.service 2>/dev/null || true
systemctl enable intel_ui_template.service 2>/dev/null || true
systemctl enable postcode.service 2>/dev/null || true
 
systemctl start composite-gadget.service
systemctl start streaming_hid.service
systemctl start usb_mass_storage.service 2>/dev/null || true
systemctl start intel_ui_template.service 2>/dev/null || true
systemctl start postcode.service 2>/dev/null || true
 
# =================================================
# FINAL STEP: RUN PROVISIONING VERIFICATION
# =================================================
echo "[FIRST BOOT] Running provisioning verification report"
 
if [ -x /home/rpi/scripts/verify_provisioning.sh ]; then
    bash /home/rpi/scripts/verify_provisioning.sh
    echo "[FIRST BOOT] Verification report generated:"
    echo "           /home/rpi/provision_verification_report.txt"
else
    echo "[WARN] Verification script not found or not executable"
fi
 
# =================================================
# MARK FIRST BOOT COMPLETE
# =================================================
touch "$MARKER"
 
echo "======================================"
echo "[FIRST BOOT] Provisioning completed successfully"
echo "======================================"
