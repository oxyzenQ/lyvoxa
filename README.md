# 🌟 Lyvoxa Stellar - Futuristic System Monitor

An optimized monitoring system linux - a next-generation system monitoring tool built in Rust, designed as a futuristic alternative to htop. Lyvoxa delivers an elegant Terminal User Interface (TUI) with advanced process management, real-time charts, and AI-powered insights.

**Current Version**: Stellar 2.0 (v2.0.0)
**Supported Platforms**: ArchLinux (recommended), Linux x86_64 universal

## ✨ Features

### 🖥️ **Advanced Process Management**
- **Complete process table** with all htop-like columns: NI, PRI, PID, USER, COMMAND, TIME, MEM, CPU%, VIRT, RES, SHR, S
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
- **F5**: Tree view toggle
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
````

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
- **F5**: Tree view toggle
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
- [ ] Configuration file support with persistence
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
