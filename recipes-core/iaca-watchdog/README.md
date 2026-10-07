# IACA Watchdog Recipe

This recipe builds the IACA Watchdog service from its Rust source code.

## Repository
- **Source**: `https://gitlab.iaca-electronique.com/iaca-os/system/iaca-os-watchdog.git`
- **License**: MIT

## Setup

1. **Generate crates.inc**: 
   ```bash
   bitbake -c update_crates iaca-watchdog
   ```

2. **Remove EXCLUDE_FROM_WORLD**: After generating crates.inc, remove or comment out the `EXCLUDE_FROM_WORLD = "1"` line in the recipe.

## Building

```bash
bitbake iaca-watchdog
```

## Files

- `iaca-watchdog_0.8.bb` - Main BitBake recipe
- `iaca-watchdog-crates.inc` - Auto-generated Cargo crate dependencies

## Configuration

The recipe uses:
- `cargo` class - For Rust/Cargo build support
- `cargo-update-recipe-crates` class - For automatic crate dependency management
- Release build mode for optimized binaries

## Init System

The recipe installs a SysVinit service script for automatic startup. The service is enabled by default via the `INIT_MANAGER` configuration (set to `sysvinit` in `iaca-os.conf`).