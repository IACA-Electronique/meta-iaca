# RAUC USB Auto-Upgrade

## Purpose
This recipe enables automatic system upgrades via USB for **iaca-os** using **RAUC**. It monitors connected USB storage devices for a valid RAUC bundle and triggers the upgrade process automatically when detected.

## USB Requirements
For the auto-upgrade to work, the USB storage device must meet the following criteria:

- **Partition Label**: The partition must be labeled **`RAUC_UPDATE`**.
- **Filesystem Type**: Must be formatted as **FAT32** (e.g., `vfat` or `msdos`). Other filesystems are not supported.
- **RAUC Bundle Filename**: The upgrade bundle must be named **`last.raucb`** and placed in the root directory of the USB device.

## Upgrade Workflow

1. **Prepare USB Device**:
   - Format the USB device as **FAT32** (e.g., `vfat` or `msdos`).
   - Label the partition as **`RAUC_UPDATE`**.
   - Copy the `last.raucb` bundle to the root directory of the USB device.

2. **Connect USB Device**:
   - Insert the prepared USB device into the target system (e.g., Raspberry Pi 5).

3. **Auto-Detection**:
   - The daemon automatically detects the USB device and scans for a partition labeled `RAUC_UPDATE` with a valid `last.raucb` bundle.

4. **Upgrade Execution**:
   - If the bundle is found, the system triggers the RAUC upgrade process automatically.
   - The system installs the new bundle, unmounts the USB device, sets the `TRYBOOT` flag (for Raspberry Pi bootloader), and broadcasts a reboot message to all TTYs.

5. **Completion**:
   - The system waits **15 seconds** and then reboots.
   - The upgrade completes, and the system runs the new version of **iaca-os**.
   - The USB device can be safely removed after the upgrade is confirmed.
