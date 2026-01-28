# Rutomatrix Intel Features – First Boot Automation

This repository provides an automated first-boot provisioning framework for Raspberry Pi systems.
On the first boot of the OS, all required packages, feature modules, services, and environments are installed automatically without manual intervention.

The provisioning process is designed to run only once, generate logs.

## What This Repository Does

- Installs required system packages
- Clones the main repository
- Deploys feature folders into /home/rpi
- Creates Python virtual environments per feature
- Installs Python dependencies
- Builds native components such as uStreamer
- Configures and enables systemd services
- Prevents re-execution on subsequent boots

## Features Provisioned

- Streaming_HID
- Postcode
- Intel UI Templates
- USB File Sharing
- System_ATX
- OS_Flashing
- Firmware
- BIOS Serial Log
- PDU
- USB Composite Gadgets
- uStreamer (built from source)

## Directory Layout After First Boot

/home/rpi/
├── Streaming_HID
├── Postcode
├── intel_UI_templates
├── USB File Sharing
├── System_Atx
├── OS_Flashing
├── Firmware
├── Bios_serial_log
├── PDU
├── gadgets
├── scripts
│   ├── first_boot_setup.sh
├── first_boot.log
└── .first_boot_done

## SD Card Preparation (Linux Laptop)

1. Flash Raspberry Pi OS Lite
2. Enable SSH and set default user as rpi
3. Insert SD card into Linux laptop

Mount root filesystem:
sudo mount /dev/sdX2 /mnt/rpi-root

Copy scripts:
sudo mkdir -p /mnt/rpi-root/home/rpi/scripts
sudo cp first_boot_setup.sh /mnt/rpi-root/home/rpi/scripts/
sudo chmod +x /mnt/rpi-root/home/rpi/scripts/*.sh

## First Boot systemd Service

Create service file at:
/mnt/rpi-root/etc/systemd/system/first-boot.service

[Unit]
Description=First Boot Setup for Rutomatrix Intel Features
After=network.target

[Service]
Type=oneshot
ExecStart=/home/rpi/scripts/first_boot_setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

Enable offline:
sudo ln -s /etc/systemd/system/first-boot.service /mnt/rpi-root/etc/systemd/system/multi-user.target.wants/first-boot.service

Unmount:
sudo umount /mnt/rpi-root
sync

## Logs and Verification

Provisioning log:
/home/rpi/first_boot.log


## Re-run Provisioning

rm /home/rpi/.first_boot_done
reboot
 30bc47a ( README is added)
