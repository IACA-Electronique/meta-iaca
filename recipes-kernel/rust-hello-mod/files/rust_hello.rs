// SPDX-License-Identifier: GPL-2.0

//! Hello world kernel module written in Rust.

use kernel::prelude::*;

module! {
    type: RustHello,
    name: "rust_hello",
    author: "Your Name",
    description: "Hello world kernel module written in Rust",
    license: "GPL",
}

struct RustHello;

impl kernel::Module for RustHello {
    fn init(_module: &'static ThisModule) -> Result<Self> {
        pr_info!("Hello world from Rust! The module is enabled.\n");
        Ok(RustHello)
    }
}

impl Drop for RustHello {
    fn drop(&mut self) {
        pr_info!("Goodbye from Rust! The module is disabled.\n");
    }
}
