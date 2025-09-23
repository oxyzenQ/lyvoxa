# 🔍 Lyvoxa - System Monitor

A high-performance, low-memory system monitoring tool written in Rust, designed to be a fast alternative to other system monitors with beautiful terminal UI. Lyvoxa provides real-time insights into your machine's performance with minimal resource overhead.

**Current Version**: Stellar 1.5 (v1.5.0)

## Features

- **Real-time CPU monitoring** with usage graphs
- **Memory usage tracking** with visual indicators
- **Process listing** sorted by CPU usage
- **Low memory footprint** - built with Rust for optimal performance
- **Fast updates** - minimal latency system monitoring
- **Beautiful TUI** - modern terminal interface using ratatui
- **Cross-platform** - works on Linux, macOS, and Windows

## Installation & Usage

### Quick Install (Recommended)

Download the latest release from [GitHub Releases](https://github.com/oxyzenQ/lyvoxa/releases) for your platform.

#### Secure Installation with Verification
```bash
# Download release and verification files
wget https://github.com/oxyzenQ/lyvoxa/releases/download/stellar-1.5/lyvoxa-stellar-1.5-linux-x86_64.tar.gz
wget https://github.com/oxyzenQ/lyvoxa/releases/download/stellar-1.5/lyvoxa-stellar-1.5-linux-x86_64.tar.gz.sha512

# Verify integrity (recommended)
sha512sum -c lyvoxa-stellar-1.5-linux-x86_64.tar.gz.sha512

# Extract and install
tar -xzf lyvoxa-stellar-1.5-linux-x86_64.tar.gz
cd lyvoxa-stellar-1.5-linux-x86_64
sudo ./install.sh
```

### Build from source

#### Quick Build (Recommended)
```bash
# Clone the repository
git clone https://github.com/oxyzenQ/lyvoxa.git
cd lyvoxa

# Use the optimized build script (limits CPU to 3 cores)
./build.sh release

# Run the full TUI version (interactive interface)
./target/x86_64-unknown-linux-gnu/release/lyvoxa

# Or run the simple terminal version
./target/x86_64-unknown-linux-gnu/release/lyvoxa-simple
```

#### Manual Build
```bash
# Build with CPU core limits (recommended for heat control)
cargo build --release --jobs 3 --target x86_64-unknown-linux-gnu

# Or use Make for automation
make release

# Or use bun for package management (if available)
bun install  # Install any additional tools
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

### Controls

**Full TUI Version:**
- `q` - Quit the application
- `Esc` - Exit the application

**Simple Version:**
- `Ctrl+C` - Exit the application

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
- **Multi-Algorithm Checksums**: SHA512, BLAKE3, ChaCha20-HMAC
- **SSH Signature Verification**: Cryptographically signed releases
- **Tamper Detection**: Multiple verification layers
- **Supply Chain Security**: Automated verification in CI/CD

## Architecture

The project is structured into two main components:

- `src/main.rs` - Full TUI interface with graphs and interactive elements
- `src/simple.rs` - Lightweight terminal output for minimal resource usage
- `src/monitor.rs` - Core system monitoring logic using the `sysinfo` crate

## Dependencies

- `sysinfo` - Cross-platform system information gathering
- `ratatui` - Terminal user interface framework
- `crossterm` - Cross-platform terminal manipulation
- `tokio` - Async runtime for responsive UI
- `humansize` - Human-readable size formatting

## Comparison with Other Competitors

| Feature | Traditional Monitors | lyvoxa |
|---------|---------------------|--------|
| Memory Usage | ~2-4 MB | ~1-2 MB |
| CPU Overhead | Medium | Low |
| Startup Time | Fast | Very Fast |
| Language | C/C++ | Rust |
| Safety | Manual memory management | Memory safe |

## Future Enhancements

- [ ] Network monitoring
- [ ] Disk I/O statistics
- [ ] Process tree view
- [ ] Configuration file support
- [ ] Custom color themes
- [ ] Process filtering and search
- [ ] Export monitoring data

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
- All releases include SHA512, BLAKE3, and ChaCha20-HMAC checksums
- SSH signatures provide cryptographic authenticity proof
- Follow verification steps before installation for maximum security

## Repository

- **GitHub**: [https://github.com/oxyzenQ/lyvoxa](https://github.com/oxyzenQ/lyvoxa)
- **Issues**: [https://github.com/oxyzenQ/lyvoxa/issues](https://github.com/oxyzenQ/lyvoxa/issues)
- **Releases**: [https://github.com/oxyzenQ/lyvoxa/releases](https://github.com/oxyzenQ/lyvoxa/releases)
- **Security**: [SECURITY.md](SECURITY.md)
