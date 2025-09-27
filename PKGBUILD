# =============================================================================
# ARCH LINUX PKGBUILD - LYVOXA SYSTEM MONITOR
# =============================================================================
# Maintainer: rezky_nightky <rezky@lyvoxa.dev>
# Contributor: rezky_nightky

pkgname=lyvoxa
pkgver=2.0.0
pkgrel=1
pkgdesc="An optimized monitoring system linux"
arch=('x86_64')
url="https://github.com/oxyzenQ/lyvoxa"
license=('GPL3')
depends=('glibc')
makedepends=('rust' 'cargo' 'mold')
provides=('lyvoxa')
conflicts=('lyvoxa-bin' 'lyvoxa-git')
source=("$pkgname-$pkgver.tar.gz::https://github.com/oxyzenQ/lyvoxa/archive/refs/tags/Stellar-2.0.tar.gz")
sha256sums=('SKIP')  # Will be updated automatically

# Build from source for maximum optimization on target system
build() {
    cd "$pkgname-Stellar-2.0"
    
    # Optimize and harden
    export RUSTFLAGS="$RUSTFLAGS -C target-cpu=native -C opt-level=3 \
        -C link-arg=-Wl,-z,relro -C link-arg=-Wl,-z,now \
        -C link-arg=-Wl,-z,noexecstack -C link-arg=-Wl,--gc-sections"
    export CARGO_TARGET_DIR="target"

    # Build release (Cargo.toml sets lto=fat, panic=abort, strip=true)
    cargo build --release --target x86_64-unknown-linux-gnu --jobs 3
}

check() {
    cd "$pkgname-Stellar-2.0"
    
    # Run tests to ensure everything works
    cargo test --release --target x86_64-unknown-linux-gnu
}

package() {
    cd "$pkgname-Stellar-2.0"
    
    # Install main binary
    install -Dm755 "target/x86_64-unknown-linux-gnu/release/$pkgname" \
        "$pkgdir/usr/bin/$pkgname"

    # Ensure stripped binary (defense-in-depth; Cargo already strips)
    strip --strip-unneeded "$pkgdir/usr/bin/$pkgname" || true
    
    # Note: lyvoxa-simple binary no longer exists (removed in Stellar 2.0)
    
    # Install documentation
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    install -Dm644 QUALITY_CHECKS.md "$pkgdir/usr/share/doc/$pkgname/QUALITY_CHECKS.md"
    
    # Install license
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    
    # Install man page (if exists)
    if [ -f "docs/$pkgname.1" ]; then
        install -Dm644 "docs/$pkgname.1" "$pkgdir/usr/share/man/man1/$pkgname.1"
    fi
    
    # Install shell completions (if exist)
    if [ -d "completions" ]; then
        # Bash completion
        if [ -f "completions/$pkgname.bash" ]; then
            install -Dm644 "completions/$pkgname.bash" \
                "$pkgdir/usr/share/bash-completion/completions/$pkgname"
        fi
        
        # Zsh completion
        if [ -f "completions/_$pkgname" ]; then
            install -Dm644 "completions/_$pkgname" \
                "$pkgdir/usr/share/zsh/site-functions/_$pkgname"
        fi
        
        # Fish completion
        if [ -f "completions/$pkgname.fish" ]; then
            install -Dm644 "completions/$pkgname.fish" \
                "$pkgdir/usr/share/fish/vendor_completions.d/$pkgname.fish"
        fi
    fi
}

# vim:set ts=4 sw=4 et:
