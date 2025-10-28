<div align="center">

# 🌟 Lyvoxa Stellar
**Next-Generation Linux System Monitor**

<p>
  <a href="https://github.com/oxyzenQ/lyvoxa/releases/latest">
    <img src="https://img.shields.io/github/v/release/oxyzenQ/lyvoxa?style=flat&logo=starship&logoColor=white&color=8B5CF6&labelColor=1E1B4B" alt="Release"/>
  </a>
  <a href="https://github.com/oxyzenQ/lyvoxa/releases">
    <img src="https://img.shields.io/github/downloads/oxyzenQ/lyvoxa/total?style=flat&logo=download&logoColor=white&color=10B981&labelColor=065F46" alt="Downloads"/>
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-GPLv3-EC4899?style=flat&logo=gnu&logoColor=white&labelColor=831843" alt="License"/>
  </a>
</p>

<p>
  <img src="https://img.shields.io/github/actions/workflow/status/oxyzenQ/lyvoxa/ci.yml?style=flat&logo=githubactions&logoColor=white&label=CI%2FCD&labelColor=1E293B" alt="CI/CD"/>
  <img src="https://img.shields.io/badge/Security-Verified-06B6D4?style=flat&logo=security&logoColor=white&labelColor=164E63" alt="Security"/>
  <img src="https://img.shields.io/aur/version/lyvoxa-bin?style=flat&logo=archlinux&logoColor=white&label=AUR&color=1793D1&labelColor=0C4A6E" alt="AUR"/>
  <img src="https://img.shields.io/github/stars/oxyzenQ/lyvoxa?style=flat&logo=github&logoColor=white&color=F59E0B&labelColor=78350F" alt="Stars"/>
</p>

---

**Elegant TUI · Real-time Monitoring · Process Management · Future-proof Architecture**

*Version 3.1.0 Stellar* | *Built with Rust* 🦀

</div>

---

## 📖 About

Lyvoxa is a professional-grade system monitoring tool for Linux, combining elegance with performance. Built from the ground up in Rust, it delivers an intuitive Terminal User Interface (TUI) with advanced features for modern system administration.

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

## 🚀 Installation

### Quick Install (Recommended)

```bash
# Download latest release (v3.1.0)
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.1.0/lyvoxa-3.1.0-linux-amd64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/3.1.0/lyvoxa-3.1.0-linux-amd64.tar.gz.sha256

# Verify integrity
sha256sum -c lyvoxa-3.1.0-linux-amd64.tar.gz.sha256

# Extract and install
tar -xzf lyvoxa-3.1.0-linux-amd64.tar.gz
sudo cp lyvoxa-3.1.0-linux-amd64/bin/* /usr/local/bin/

# Run
lyvoxa
```

**Verification**: See [docs/VERIFICATION.md](docs/VERIFICATION.md) for SHA256 + GPG signature verification.

### ArchLinux (AUR - repository)

```bash
# Available on AUR

yay -S lyvoxa-bin

or

paru -S lyvoxa-bin
```

### Build from Source

```bash
# Clone repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Build release
cargo build --release --target x86_64-unknown-linux-gnu

# Or use Makefile
make release

# Run
./target/x86_64-unknown-linux-gnu/release/lyvoxa
```

## 🎮 Usage

Run `lyvoxa` in your terminal. Use function keys (F1-F10) for navigation:

| Key | Action | Description |
|-----|--------|-------------|
| **F1** | Help | Show all shortcuts |
| **F2** | Setup | Configuration menu |
| **F3** | Search | Find processes |
| **F4** | Filter | Filter process list |
| **F5** | Charts | Toggle graphs on/off |
| **F6** | Sort | Change sort mode |
| **F7/F8** | Nice | Adjust process priority |
| **F9** | Kill | Terminate process |
| **F10** | Quit | Exit application |
| **Tab** | Theme | Cycle themes |
| **↑/↓** | Navigate | Select process |
| **q** | Quick quit | Fast exit |

## ⚙️ Configuration

Auto-created at `~/.config/lyvoxa/config.toml` on first run. Settings persist automatically:

```toml
ui_rate_ms = 500          # UI refresh (ms)
data_rate_ms = 5000       # Data polling (ms)
max_rows = 20             # Process table rows
show_charts = true        # Enable charts
theme = "stellar"         # dark | stellar | matrix
sort = "cpu"              # cpu | mem | pid | user | command
```

**Config priority**: `LYVOXA_CONFIG` env → local dir → `/etc/lyvoxa` → `~/.config/lyvoxa`

## 🎯 Why Lyvoxa?

| Feature | Traditional | Lyvoxa |
|---------|-------------|--------|
| **Memory** | ~2-4 MB | ~1-2 MB ✅ |
| **Safety** | Manual (C/C++) | Memory-safe (Rust) ✅ |
| **Performance** | Good | Optimized ✅ |
| **Security** | Basic | SHA256 + GPG ✅ |
| **Build** | - | Reproducible + Hardened ✅ |

**Key advantages:**
- 🦀 Rust: Zero-cost abstractions, memory safety
- ⚡ Fast: LTO optimization, native compilation
- 🔒 Secure: Binary hardening, signed releases
- 📦 Small: ~1.3MB optimized binary

## 🏗️ Technical Stack

**Core:** Rust 1.90+ | **TUI:** Ratatui + Crossterm | **Async:** Tokio
**System:** procfs + sysinfo + nix | **Build:** Cargo + LTO

## 📚 Documentation

- **[Verification Guide](docs/VERIFICATION.md)** - SHA256 + GPG verification (Bahasa)
- **[GPG Setup](docs/GITHUB_GPG_SETUP.md)** - Auto-signing configuration
- **[Security Policy](docs/SECURITY.md)** - Security best practices
- **[Contributing](docs/CONTRIBUTING.md)** - Contribution guidelines

## 🤝 Contributing

Contributions welcome! Please:
1. Open an issue for major changes
2. Fork → Feature branch → PR
3. Follow [DCO](docs/CONTRIBUTING.md#developer-certificate-of-origin-dco)
4. Sign commits with GPG (recommended)

## 📄 License & Trademark

**License:** [GNU GPL v3.1.0](LICENSE) - Free to use, modify, and redistribute
**Trademark:** "Lyvoxa" ™ Rezky Nightky (2025) - Name & logo protected

For commercial licensing or brand usage: [with.rezky@gmail.com](mailto:with.rezky@gmail.com)

---

<div align="center">

**Made with 🦀 by [Rezky Nightky](https://github.com/oxyzenQ)**

[GitHub](https://github.com/oxyzenQ/lyvoxa) · [Releases](https://github.com/oxyzenQ/lyvoxa/releases) · [Issues](https://github.com/oxyzenQ/lyvoxa/issues) · [Security](docs/SECURITY.md)

*Professional system monitoring for Linux · Built for performance, designed for elegance*

</div>
