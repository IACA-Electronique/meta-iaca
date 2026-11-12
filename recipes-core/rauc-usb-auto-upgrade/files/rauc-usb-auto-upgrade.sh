#!/bin/bash
#
# RAUC USB Auto Upgrade Daemon
# Monitors USB storage devices for RAUC update bundles
#

# =============================================================================
# EXIT STATUS CODES
# =============================================================================
#  0 - Success
# 10 - Failed to create log directory
# 11 - Failed to create mount point directory  
# 12 - Failed to write PID file
# 13 - Failed to load configuration file
# 14 - Failed to unmount device during cleanup
# 15 - Failed to start main loop (PID file conflict)
# 16 - Failed to read partition information
# 17 - Failed to check partition type
# 18 - Failed to mount partition
# 19 - RAUC bundle file not found
# 20 - RAUC update installation failed
# =============================================================================

# Configuration
CONFIG_FILE="/etc/rauc-usb-auto-upgrade/config"
MOUNT_POINT="/mnt/rauc_update"
LOG_FILE="/var/log/rauc-usb-auto-upgrade.log"
PID_FILE="/var/run/rauc-usb-auto-upgrade.pid"

# Default values (can be overridden in config file)
PARTITION_LABEL="RAUC_UPDATE"

# Interval between checks (in seconds)
POLL_INTERVAL=5

# Rauc bundle filename to look for
RAUC_BUNDLE_FILE="last.raucb"

# Logging function
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# Error logging function with exit code
error_exit() {
    local exit_code=$1
    local message=$2
    log "ERROR: $message (exit code: $exit_code)"
    cleanup
    exit $exit_code
}

# Cleanup function
cleanup() {
    log "Cleaning up..."
    
    # Unmount device if mounted
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        log "Unmounting $MOUNT_POINT"
        umount "$MOUNT_POINT" 2>/dev/null || {
            log "Failed to unmount $MOUNT_POINT, trying lazy unmount..."
            umount -l "$MOUNT_POINT" 2>/dev/null || {
                log "Failed to lazy unmount $MOUNT_POINT" || error_exit 14 "Critical: Could not unmount $MOUNT_POINT"
            }
        }
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    log "Cleanup complete."
}

signal_install_done() {
    vcmailbox 0x00038064 4 0 1
}

# Trap signals for cleanup
trap cleanup SIGTERM SIGINT SIGHUP SIGQUIT

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")" || error_exit 10 "Failed to create log directory"

# Ensure mount point exists
mkdir -p "$MOUNT_POINT" || error_exit 11 "Failed to create mount point directory"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE" || error_exit 13 "Failed to load configuration file"
fi

# Check if PID file already exists and process is running
if [ -f "$PID_FILE" ]; then
    existing_pid=$(cat "$PID_FILE" 2>/dev/null || echo "")
    if [ -n "$existing_pid" ] && ps -p "$existing_pid" > /dev/null 2>&1; then
        log "Another instance is already running (PID: $existing_pid)" || error_exit 15 "PID file conflict"
        exit 0
    else
        # Stale PID file, remove it
        rm -f "$PID_FILE"
    fi
fi

# Write PID file
echo $$ > "$PID_FILE" || error_exit 12 "Failed to write PID file"

log "RAUC USB Auto Upgrade Daemon started (PID: $$)"
log "Monitoring for USB devices with partition label: $PARTITION_LABEL"
log "Looking for file: $RAUC_BUNDLE_FILE"

# Main loop
while true; do
    # Check all block devices
    for device in /dev/sd*; do
        # Skip if device doesn't exist or is not a block device
        [ -b "$device" ] || continue
        
        # Skip if it's the current root device or boot device
        case "$device" in
            /dev/mmcblk*)
                continue
                ;;
        esac
        
        # Check if device has partitions
        partitions=$(lsblk -lnb -o NAME "${device}" 2>/dev/null | tail -n +2) || {
            log "Failed to list partitions for $device" || error_exit 16 "Failed to read partition information for $device"
            continue
        }
        
        for partition in $partitions; do
            partition_device="/dev/${partition}"
            
            # Skip if partition doesn't exist
            [ -b "$partition_device" ] || continue
            
            # Skip if already mounted (avoid processing same device multiple times)
            mountpoint -q "$partition_device" 2>/dev/null && continue
            
            # Get partition information
            part_info=$(blkid -o export "$partition_device" 2>/dev/null) || {
                log "Failed to get partition info for $partition_device" || error_exit 16 "Failed to read partition information for $partition_device"
                continue
            }
            
            # Check if this partition has our label
            if echo "$part_info" | grep "LABEL=${PARTITION_LABEL}" > /dev/null; then
                log "Found potential update device: $partition_device"
                
                # Check if partition is FAT
                part_type=$(echo "$part_info" | grep "^TYPE=" | cut -d'=' -f2) || {
                    log "Failed to determine partition type for $partition_device" || error_exit 17 "Failed to check partition type for $partition_device"
                    continue
                }
                
                if [ "$part_type" != "vfat" ] && [ "$part_type" != "msdos" ]; then
                    log "Skipping $partition_device: Not a FAT partition (type: $part_type)"
                    continue
                fi
                
                log "Mounting $partition_device as read-only..."
                
                # Try to mount the partition
                if mount -o ro "$partition_device" "$MOUNT_POINT" 2>/dev/null; then
                    log "Successfully mounted $partition_device at $MOUNT_POINT"
                    
                    # Check if the RAUC bundle file exists
                    bundle_path="${MOUNT_POINT}/${RAUC_BUNDLE_FILE}"
                    
                    if [ -f "$bundle_path" ]; then
                        log "Found RAUC bundle: $bundle_path"
                        log "Starting RAUC update installation..."
                        
                        # Perform RAUC update
                        if rauc install "$bundle_path" >> "$LOG_FILE" 2>&1; then
                            log "RAUC update successful!"
                            log "Preparing system reboot..."
                            
                            # Unmount before reboot
                            umount "$MOUNT_POINT" 2>/dev/null || umount -l "$MOUNT_POINT" 2>/dev/null || {
                                log "Warning: Could not unmount before reboot" || true
                            }

                            # Set TRYBOOT flag (Raspberry bootloader)
                            signal_install_done || {
                                log "Failed to set tryboot flag, exiting anyway" || true
                                cleanup
                                exit 0
                            }

                            # Broadcast reboot message to all TTYs
                            wall "System update completed. Rebooting in 15 seconds..." || true
                            log "Broadcasted reboot message to all TTYs"
                            
                            # Wait 15 seconds before reboot
                            sleep 15
                            
                            # Reboot system
                            log "Rebooting system..."
                            reboot || {
                                log "Failed to reboot, exiting anyway" || true
                                cleanup
                                exit 0
                            }
                            
                        else
                            log "RAUC update failed!" || error_exit 20 "RAUC update installation failed for $bundle_path"
                        fi
                    else
                        log "RAUC bundle $RAUC_BUNDLE_FILE not found on $partition_device" || error_exit 19 "RAUC bundle file not found on $partition_device"
                    fi
                else
                    log "Failed to mount $partition_device" || error_exit 18 "Failed to mount partition $partition_device"
                fi
                
                # Short delay to avoid rapid retry on same device
                sleep 2
                
            fi
        done
    done
    
    # Wait before checking again
    sleep "$POLL_INTERVAL"
    
done
