# 🌟 Lyvoxa Stellar - Futuristic System Monitor

<!-- Badges: Build · Security · Release · Platform · Activity · Branding -->
<p align="center">
  <!-- Build & CI -->
  <a href="https://github.com/oxyzenQ/lyvoxa/actions/workflows/ci.yml">
    <img alt="Build CI"
         src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/ci.yml?branch=main&label=build&style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/actions/workflows/codeql.yml">
    <img alt="CodeQL"
         src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/codeql.yml?branch=main&label=codeql&style=for-the-badge">
  </a>
  <a href="https://securityscorecards.dev/viewer/?uri=github.com/oxyzenQ/lyvoxa">
    <img alt="OpenSSF Scorecard"
         src="https://img.shields.io/ossf-scorecard/github.com/oxyzenQ/lyvoxa?label=OpenSSF%20Scorecard&style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/actions/workflows/dco.yml">
    <img alt="DCO"
         src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/dco.yml?branch=main&label=dco&style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/actions/workflows/release.yml">
    <img alt="Release Pipeline"
         src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/release.yml?branch=main&label=release&style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/actions/workflows/clone-detect.yml">
    <img alt="Clone Detect"
         src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/clone-detect.yml?branch=main&label=clone%20detect&style=for-the-badge">
  </a>
  <a href="LICENSE">
    <img alt="License"
         src="https://img.shields.io/github/license/oxyzenQ/lyvoxa?style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/releases">
    <img alt="Latest Release"
         src="https://img.shields.io/github/v/release/oxyzenQ/lyvoxa?display_name=tag&sort=semver&style=for-the-badge">
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/releases">
    <img alt="Downloads"
         src="https://img.shields.io/github/downloads/oxyzenQ/lyvoxa/total?style=for-the-badge">
  </a>
</p>

<p align="center">
  <!-- Platform & Security -->
  <img alt="Arch Linux"
       src="https://img.shields.io/badge/ArchLinux-recommended-1793D1?logo=arch-linux&logoColor=white&style=for-the-badge">
  <img alt="Linux x86_64"
       src="https://img.shields.io/badge/Linux-x86__64-black?logo=linux&logoColor=white&style=for-the-badge">
  <img alt="Checksum SHA256"
       src="https://img.shields.io/badge/checksum-SHA256-blue?style=for-the-badge">
</p>

<p align="center">
  <!-- Code & Activity -->
  <img alt="Lines of Code"
       src="https://img.shields.io/tokei/lines/github/oxyzenQ/lyvoxa?style=for-the-badge">
  <img alt="Commit Activity"
       src="https://img.shields.io/github/commit-activity/m/oxyzenQ/lyvoxa?style=for-the-badge">
  <img alt="Last Commit"
       src="https://img.shields.io/github/last-commit/oxyzenQ/lyvoxa?style=for-the-badge">
</p>

<p align="center">
  <!-- Branding (futuristic) -->
  <img alt="Stellar Edition"
       src="https://img.shields.io/badge/edition-stellar-7D2AE8?style=for-the-badge&logo=starship&logoColor=white">
  <img alt="Themes"
       src="https://img.shields.io/badge/themes-Stellar%20%7C%20Matrix-00d084?style=for-the-badge">
  <img alt="Plugin Ready"
       src="https://img.shields.io/badge/plugin-ready-00bcd4?style=for-the-badge&logo=puzzle&logoColor=white">
</p>

<!-- Optional badges (uncomment when ready)
<p align="center">
  <a href="https://www.bestpractices.dev/"><img alt="OpenSSF Best Practices"
     src="https://img.shields.io/ossf-scorecard/github.com/oxyzenQ/lyvoxa?label=openssf%20scorecard&style=for-the-badge"></a>
  <a href="https://crates.io/crates/lyvoxa"><img alt="crates.io"
     src="https://img.shields.io/crates/v/lyvoxa?style=for-the-badge"></a>
  <a href="https://aur.archlinux.org/packages/lyvoxa"><img alt="AUR"
     src="https://img.shields.io/aur/version/lyvoxa?style=for-the-badge"></a>
  <a href="https://formulae.brew.sh/"><img alt="Homebrew"
     src="https://img.shields.io/badge/homebrew-coming_soon-orange?logo=homebrew&style=for-the-badge"></a>
</p>
-->

An optimized monitoring system linux - a next-generation system monitoring tool built in Rust, designed as a futuristic alternative to traditional system monitors. Lyvoxa delivers an elegant Terminal User Interface (TUI) with advanced process management, real-time charts, and AI-powered insights.

**Current Version**: Stellar 2.0 (v2.0.0)
**Supported Platforms**: ArchLinux (recommended), Linux x86_64 universal

## ✨ Features

### 🖥️ **Advanced Process Management**

- **Complete process table** with all columns found in traditional system monitors: NI, PRI, PID, USER, COMMAND, TIME, MEM, CPU%, VIRT, RES, SHR, S
- **Interactive process control** - adjust nice values, kill processes
- **Real-time filtering and search** with live updates
- **Multiple sort modes** - CPU, memory, PID, user, command
- **Process selection** with arrow key navigation

### 📊 **Real-time System Monitoring**

- **Per-core CPU monitoring** with individual gauges for all CPU cores
- **Memory usage tracking** with detailed statistics and visual gauges
- **Network I/O monitoring** with RX/TX bytes per second
- **Historical charts** for CPU, memory, and network with 120-point rolling history
- **Live system metrics** updated every second

### 🎨 **Beautiful Theming System**

- **Three elite themes**: Dark (professional), **Stellar** (space/neon), Matrix (green cyber)
- **Runtime theme switching** with Tab key hotkey
- **Consistent color schemes** across all UI elements
- **Futuristic visual design** with smooth transitions

### ⌨️ **Professional Keyboard Controls (F1-F10)**

- **F1**: Help overlay with all shortcuts
- **F2**: Setup and configuration
- **F3**: Live search processes
- **F4**: Filter processes
- **F5**: Charts toggle (on/off)
- **F6**: Cycle sort modes
- **F7/F8**: Adjust process priority (nice)
- **F9**: Kill selected process
- **F10**: Quit application

## Installation & Usage

### Quick Install (Recommended)

Download the latest release from [GitHub Releases](https://github.com/oxyzenQ/lyvoxa/releases) for your platform.

#### Linux Universal Installation

```bash
# Download universal Linux package
wget https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/Stellar-2.0/lyvoxa-Stellar-2.0-linux-x86_64.tar.gz.sha256

# Verify integrity (SHA256 - universal standard)
sha256sum -c lyvoxa-Stellar-2.0-linux-x86_64.tar.gz.sha256

# Extract and install
tar -xzf lyvoxa-Stellar-2.0-linux-x86_64.tar.gz

# Copy to system path
sudo cp lyvoxa /usr/local/bin/
```

#### ArchLinux Installation (PKGBUILD)

```bash
# For proper system integration
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa
make arch-pkg
sudo pacman -U lyvoxa-*.pkg.tar.zst
```

### Build from source

#### Quick Build (Recommended)

```bash
# Clone the repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Use the optimized build script (limits CPU to 3 cores)
./build.sh release

# Run the TUI system monitor
./target/x86_64-unknown-linux-gnu/release/lyvoxa
```

#### Manual Build

```bash
# Build with CPU core limits (recommended for heat control)
cargo build --release --jobs 3 --target x86_64-unknown-linux-gnu

# Or use Make for automation
make release

make all     # Full build cycle
```

#### Manual Build

```bash
# Build from source
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa
./build.sh release

# Run the application
./target/x86_64-unknown-linux-gnu/release/lyvoxa
```

### 🎮 Controls

**Keyboard Shortcuts:**

- **F1**: Help overlay
- **F2**: Setup menu
- **F3**: Search processes
- **F4**: Filter processes
- **F5**: Charts toggle (on/off)
- **F6**: Sort mode cycling
- **F7**: Decrease process priority (Nice-)
- **F8**: Increase process priority (Nice+)
- **F9**: Kill selected process
- **F10**: Quit application
- **F11/F12**: Theme cycling (bonus)
- **↑/↓**: Navigate process list
- **q**: Quick quit
- **Enter**: Confirm in dialogs
- **Esc**: Close overlays

## Configuration

Lyvoxa reads configuration from a simple TOML file and persists your changes automatically.

- **Precedence (highest to lowest):**

  1. `LYVOXA_CONFIG=/path/to/config.toml`
  2. `./lyvoxa.toml` | `./lyvoxa/config.toml` | `./config/lyvoxa.toml`
  3. `./config.toml` (only if valid Lyvoxa AppConfig)
  4. `/etc/lyvoxa/config.toml` (system-wide fallback)
  5. `~/.config/lyvoxa/config.toml` (XDG-compliant; created on first run)

- **What persists from the TUI:**

  - Theme (Tab cycling)
  - Sort mode (F6)
  - Charts on/off (F5)

- **Environment overrides (session-only):** `LYVOXA_UI_MS`, `LYVOXA_DATA_MS`, `LYVOXA_ROWS`, `LYVOXA_SHOW_CHARTS`

Example `config.toml`:

```toml
# UI redraw interval in milliseconds
ui_rate_ms = 500

# System data refresh interval in milliseconds
data_rate_ms = 5000

# Maximum number of process rows shown in the table
max_rows = 20

# Show charts on startup
show_charts = true

# Startup theme: "dark" | "stellar" | "matrix"
theme = "stellar"

# Default sort: "cpu" | "mem" | "pid" | "user" | "command"
sort = "cpu"
```

## Performance Benefits

This Rust-based monitor offers several advantages over traditional system monitors:

1. **Memory Efficiency**: Rust's zero-cost abstractions and memory safety without garbage collection
2. **Low CPU Overhead**: Compiled binary with optimized system calls
3. **Fast Startup**: No interpreter or virtual machine overhead
4. **Minimal Dependencies**: Self-contained binary with minimal runtime requirements

## Build Optimization

Lyvoxa uses an advanced build system optimized for developer machines:

### 🔥 **Heat Control**

- **CPU Core Limiting**: All builds limited to 3 cores maximum to prevent overheating
- **Incremental Compilation**: Faster rebuilds with cached artifacts
- **sccache Integration**: Shared compilation cache for even faster builds

### ⚡ **Performance Features**

- **Target-Specific Optimization**: Builds optimized for `x86_64-unknown-linux-gnu`
- **Link-Time Optimization (LTO)**: Smaller, faster binaries
- **Native CPU Features**: Automatically uses your CPU's capabilities
- **Mold Linker Support**: Faster linking when available

### 🛠️ **Build Profiles**

- `debug`: Fast compilation for development
- `release`: Maximum optimization for production
- `release-with-debug`: Optimized with debug info for profiling

### 📦 **Reproducible Builds**

- Locked Rust toolchain via `rust-toolchain.toml`
- Dependency locking with `Cargo.lock`
- Containerized builds with Docker

### 🔐 **Security & Integrity**

- **SHA256 Checksum**: Universal standard for integrity verification
- **Reproducible Builds**: Consistent build environment and toolchain
- **Memory Safety**: Rust's zero-cost abstractions prevent common vulnerabilities
- **Supply Chain Security**: Automated verification in CI/CD

### 🔒 Binary Hardening & High‑Effort RE

Lyvoxa enables strong hardening by default for release builds:

- LTO: `lto = "fat"` and `codegen-units = 1` for aggressive cross‑crate inlining
- Optimizations: `opt-level = 3` for maximal flattening and performance
- Strip: `strip = true` to remove symbols and debug info at link time
- Panic behavior: `panic = "abort"` to remove unwind metadata
- Linker hardening flags (via `.cargo/config.toml`):
  - `-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,--gc-sections`
- Runtime hardening (Linux): disable core dumps with `prctl(PR_SET_DUMPABLE,0)`
- Selective string obfuscation (via `obfstr`) for sensitive literals

#### Quick presets (already applied)

```
[profile.release]
opt-level = 3
lto = "fat"
codegen-units = 1
panic = "abort"
strip = true
```

#### Arch PKGBUILD

The `PKGBUILD` builds with release profile and strips the installed binary. It also exports hardening flags during the build. See `PKGBUILD` for details.

#### Verify hardening (Linux)

```bash
# Build
cargo build --release -j 3

# Inspect binary
BIN=target/x86_64-unknown-linux-gnu/release/lyvoxa
file "$BIN"

# Check RELRO, BIND_NOW and NX stack
readelf -lW "$BIN" | sed -n '/Program Headers:/,/Section to Segment/p'
readelf -d "$BIN" | grep -E 'BIND_NOW|RELRO' || true

# GNU_STACK should be RW, not RWE (noexecstack)
readelf -lW "$BIN" | grep GNU_STACK

# Optional (install checksec):
# pacman -S checksec
# checksec --file="$BIN"
```

Expected indicators:

- `GNU_RELRO` segment present
- `BIND_NOW` in dynamic section
- `GNU_STACK` flags without `E` (non‑executable stack)
- No debug symbols reported by `file`

## 🏗️ Architecture

The project features a clean, modular architecture:

- `src/main.rs` - Advanced TUI interface with real-time charts and interactive controls
- `src/monitor.rs` - Core system monitoring with procfs integration for detailed process info
- `src/theme.rs` - Elegant theming system with multiple visual styles
- Built with modern async Rust using tokio for responsive performance

## 📦 Dependencies

- `sysinfo` - Cross-platform system information gathering
- `ratatui` - Modern terminal user interface framework
- `crossterm` - Cross-platform terminal manipulation
- `tokio` - Async runtime for responsive UI
- `procfs` - Linux /proc filesystem parsing for detailed process info
- `users` - User name resolution
- `nix` - Unix system calls for process control
- `humansize` - Human-readable size formatting

## Comparison with Other Competitors

| Feature           | Traditional Monitors     | lyvoxa      |
| ----------------- | ------------------------ | ----------- |
| Memory Usage      | ~2-4 MB                  | ~1-2 MB     |
| CPU Overhead      | Medium                   | Low         |
| Startup Time      | Fast                     | Very Fast   |
| Language          | C/C++                    | Rust        |
| Safety            | Manual memory management | Memory safe |
| ArchLinux Support | Basic                    | Optimized   |

## 🚀 Future Enhancements

- [ ] Disk I/O statistics and charts
- [ ] Advanced process tree visualization
- [x] Configuration file with persistence (project-local + XDG + env overrides)
- [ ] Custom color theme creation
- [ ] Export monitoring data (CSV, JSON)
- [ ] Plugin system for extensibility
- [ ] Remote monitoring capabilities

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## License & Brand

Lyvoxa is released under the GNU GPL v3.0 — you are free to use, modify, and redistribute the source under the same license.
Binary releases are signed and reproducible; verify signatures and checksums before use.

Trademark: The name "Lyvoxa" and its logo are the property of Rezky Nightky. Use of the Lyvoxa name and logo in derivative or competing products requires explicit permission. For commercial licensing or partnership inquiries, contact: with.rezky@gmail.com

### Trademark Notice

“Lyvoxa” and the Lyvoxa logo are trademarks of Rezky Nightky (first use: 2025).
This repository and its public commit history serve as documented evidence of first use and ongoing development.

Use of the “Lyvoxa” name, logo, or confusingly similar branding in derivative or competing products without written permission is prohibited.
Nominative fair use—for example, referencing or linking to this project—is permitted as long as it does not imply endorsement, sponsorship, or official affiliation.

If the trademark is registered in any jurisdiction, registered trademark (®) protections will apply there. This document will be updated to reflect registration status (TM/®) when completed.

For permission requests, brand usage guidelines, or commercial licensing, contact: with.rezky@gmail.com

## Security

For security verification instructions and best practices, see [SECURITY.md](SECURITY.md).

**Release Verification:**

- All releases include SHA256 checksums (universal standard)
- Reproducible builds ensure consistent binary generation
- Follow verification steps before installation for maximum security

## Repository

- **GitHub**: [https://github.com/oxyzenQ/lyvoxa](https://github.com/oxyzenQ/lyvoxa)
- **Issues**: [https://github.com/oxyzenQ/lyvoxa/issues](https://github.com/oxyzenQ/lyvoxa/issues)
- **Releases**: [https://github.com/oxyzenQ/lyvoxa/releases](https://github.com/oxyzenQ/lyvoxa/releases)
- **Security**: [SECURITY.md](SECURITY.md)
