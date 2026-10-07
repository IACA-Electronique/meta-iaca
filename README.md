# Custom IACA layer

This layer provides custom image types, classes, and recipes for IACA OS builds.

* **Maintainer**: Julien FAURE <julien.faure@iaca-electronique.com>

## IACA image format

To generate a standard IACA image, add the following configuration to `local.conf`:

```
IMAGE_CLASSES += "image_types_iaca image_types_dir"
IMAGE_FSTYPES = "dir iaca"
```

## IACA image format with A/B partitions

To generate an IACA image using A/B partitions, add the following configuration to `local.conf`:

```
IMAGE_CLASSES += "image_types_iaca_a_b image_types_dir"
IMAGE_FSTYPES = "dir iaca_a_b"
```

---

## BitBake Classes

This layer includes the following BitBake classes in `classes/`:

### Image Type Classes

#### `image_types_iaca.bbclass`
Provides the IACA image format for standard single-rootfs images.

#### `image_types_iaca_a_b.bbclass`
Provides the IACA image format with redundant A/B rootfs partitions for failover support.

#### `image_types_dir.bbclass`
Provides directory image type functionality required by IACA image classes.

### Rust Support Classes

#### `rust-kernel-toolchain.bbclass`
Configures Rust toolchain support for Linux kernel module development. Sets up environment variables for Rust compiler, bindgen, and libclang paths. Inherits `rust-check` for version validation.

#### `rust-check.bbclass`
Performs version checks for Rust toolchain components. Validates:
- Rust toolchain directory existence
- Rust compiler version (minimum 1.78.0)
- Bindgen version (minimum 0.65.1)

---

## Core Recipes

This layer includes core system and initramfs recipes located in `recipes-core/`:

### Assets

#### IACA Assets (`iaca-assets`)
Deploys custom configuration assets including:
- `16GB.json` - Standard image configuration
- `16GB_a_b.json` - A/B partition image configuration
- `a_b/autoboot.txt` - A/B boot configuration

To build the recipe individually:
```
bitbake iaca-assets
```

### Initramfs Recipes

#### Initramfs Encryption Files (`initramfs-encryption-files`)
Provides the initialization script (`/init`) and essential device nodes (`/dev/console`, `/dev/null`) for early boot encrypted rootfs unlocking in an initramfs environment.

The `/init` script:
- Mounts essential filesystems (`/proc`, `/sys`, `/dev`).
- Parses kernel command-line parameters (`root=` and `encryptkey=`).
- Unlocks the LUKS encrypted partition using `cryptsetup luksOpen`.
- Mounts the decrypted device mapper (`/dev/mapper/disk0`) to `/newroot`.
- Moves mounts and executes `switch_root` to transition to the real rootfs (`/sbin/init`).

To build the recipe individually:
```
bitbake initramfs-encryption-files
```

To build the associated encrypted initramfs image:
```
bitbake custom-initramfs-encryption-image
```

#### Initramfs Files (`initramfs-files`)
Provides custom files for initramfs including:
- `/init` - Initialization script
- `/iaca-splash.sh` - IACA splash screen script
- Essential device nodes (`/dev/console`, `/dev/null`)

To build the recipe individually:
```
bitbake initramfs-files
```

#### Initramfs Overlay Files (`initramfs-overlay-files`)
Provides overlay files for initramfs with overlayfs support including:
- `/init` - Initialization script
- `/iaca-splash.sh` - IACA splash screen script
- `/overlay.sh` - Overlay filesystem setup script
- Essential device nodes (`/dev/console`, `/dev/null`)

To build the recipe individually:
```
bitbake initramfs-overlay-files
```

#### IACA Watchdog (`iaca-watchdog`)
Rust-based system watchdog service for monitoring and recovering from system failures. Includes SysVinit service support when `INIT_MANAGER` is set to `sysvinit`.

To build the recipe individually:
```
bitbake iaca-watchdog
```

### Image Recipes

#### Custom Initramfs Image (`custom-initramfs-image`)
Custom initramfs image with essential packages and `initramfs-files`.

To build the image:
```
bitbake custom-initramfs-image
```

#### Custom Initramfs Encryption Image (`custom-initramfs-encryption-image`)
Custom initramfs image for encrypted root filesystem support using `initramfs-encryption-files`.

To build the image:
```
bitbake custom-initramfs-encryption-image
```

#### Overlay Initramfs Image (`overlay-initramfs-image`)
Initramfs image with overlayfs support using `initramfs-overlay-files`.

To build the image:
```
bitbake overlay-initramfs-image
```

#### IACA OS Minimal Image (`iaca-os-image-minimal`)
Minimal IACA OS image with essential packages including:
- Kernel modules
- Bash and utility packages (raspi-utils, util-linux, i2c-tools)
- Rust examples (hello-rust, rust-hello-mod, colors)
- IACA services (iaca-watchdog, iaca-os-exec, iaca-os-infos, iaca-os-infos-daemon)

Supports Raspberry Pi 4 and 5. Produces multiple image types: `rpi-sdimg`, `tar.gz`, `dir`, and `iaca`.

To build the image:
```
bitbake iaca-os-image-minimal
```

---

## OS Recipes

This layer includes OS-level recipes located in `recipes-os/`:

### IACA Core Library (`iaca-core-lib`)
Rust-based library providing low-level functions for IACA OS. Built from GitLab source with cargo.

To include it in your image:
```
IMAGE_INSTALL:append = " iaca-core-lib"
```

Or build it individually:
```
bitbake iaca-core-lib
```

### IACA OS Exec (`iaca-os-exec`)
Rust-based system execution service that manages IACA OS execution environment. Installs to `/usr/local/iaca/os/exec/` with symbolic link in `/usr/sbin/os`.

To include it in your image:
```
IMAGE_INSTALL:append = " iaca-os-exec"
```

Or build it individually:
```
bitbake iaca-os-exec
```

### IACA OS Infos (`iaca-os-infos`)
Bash-based scripts for managing system information. Installs command scripts to `/usr/local/iaca/os/exec/commands/infos/`.

To include it in your image:
```
IMAGE_INSTALL:append = " iaca-os-infos"
```

Or build it individually:
```
bitbake iaca-os-infos
```

### IACA OS Infos Daemon (`iaca-os-infos-daemon`)
Rust-based daemon that maps I2C board manager information to the filesystem. Includes SysVinit service support when `INIT_MANAGER` is set to `sysvinit`.

To include it in your image:
```
IMAGE_INSTALL:append = " iaca-os-infos-daemon"
```

Or build it individually:
```
bitbake iaca-os-infos-daemon
```

---

## Kernel Recipes

This layer includes kernel-related recipes located in `recipes-kernel/`:

### Linux Raspberry Pi (`linux-raspberrypi`)
Kernel configuration for Raspberry Pi with custom features including Rust support. Adds custom configuration files and inherits `rust-kernel-toolchain`.

### Make Module Scripts (`make-mod-scripts`)
Kernel module build scripts with Rust support. Configures build environment to prevent GCC-specific flags from being passed to rustc, ensuring out-of-tree Rust modules can build successfully.

### Rust Hello Module (`rust-hello-mod`)
Hello world Linux kernel module written in Rust. Demonstrates Rust kernel module development. Automatically loads at boot via `KERNEL_MODULE_AUTOLOAD`.

To include it in your image:
```
IMAGE_INSTALL:append = " rust-hello-mod"
```

Or build it individually:
```
bitbake rust-hello-mod
```

---

## Example Recipes

This layer includes example recipes located in `recipes-example/`:

### Hello World (`hello`)
A simple "Hello, World!" C application.

To include it in your image, add the following configuration to `local.conf`:
```
IMAGE_INSTALL:append = " hello"
```

Or build it individually:
```
bitbake hello
```

### Framebuffer Colors (`colors`)
A test application that writes random colors to the framebuffer device (`/dev/fb0`) every 2 seconds.

To include it in your image, add the following configuration to `local.conf`:
```
IMAGE_INSTALL:append = " colors"
```

Or build it individually:
```
bitbake colors
```

### Hello Rust (`hello-rust`)
A simple "Hello, World!" application written in Rust, demonstrating Rust language support in Yocto.

To include it in your image, add the following configuration to `local.conf`:
```
IMAGE_INSTALL:append = " hello-rust"
```

Or build it individually:
```
bitbake hello-rust
```

### Example Banner (`example`)
A sample recipe demonstrating a custom BitBake Python task (`do_display_banner`) that displays a banner during the build.

To build and execute the recipe:
```
bitbake example
```

---

## Notes

- The `dir` image type is required because the IACA image classes use the generated root filesystem directory as input.
- Use `iaca` for a single-rootfs image.
- Use `iaca_a_b` when building an image with redundant A/B rootfs partitions (see [Raspberry Pi A/B Redundant Partitioning Guide](../../docs/a_b%20partition/README.md)).
- Rust-based recipes require appropriate Rust toolchain configuration in your build environment.
- Kernel Rust modules require the `rust-kernel-toolchain.bbclass` configuration with `RUST_KERNEL_TOOLCHAIN` and `RUST_KERNEL_BINDGEN_DIR` variables set in `local.conf`.