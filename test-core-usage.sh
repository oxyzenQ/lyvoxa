#!/bin/bash
# Test script to verify CPU core usage during Rust compilation

echo "🔍 Testing CPU Core Usage During Rust Compilation"
echo "================================================="

echo "System Information:"
echo "- Total CPU cores: $(nproc)"
echo "- System MAKEFLAGS: $(grep MAKEFLAGS /etc/makepkg.conf)"
echo ""

echo "Project Configuration:"
echo "- Configured jobs: 3"
echo "- Target: x86_64-unknown-linux-gnu"
echo ""

echo "Testing different build methods:"
echo ""

# Test 1: Direct cargo build
echo "1. Testing: cargo build (should use system default = 16 cores)"
echo "   Command: cargo build --target x86_64-unknown-linux-gnu"
echo "   Expected: Uses all 16 cores (system MAKEFLAGS)"
echo ""

# Test 2: Cargo build with explicit jobs
echo "2. Testing: cargo build --jobs 3 (explicit override)"
echo "   Command: cargo build --jobs 3 --target x86_64-unknown-linux-gnu"
echo "   Expected: Uses exactly 3 cores"
echo ""

# Test 3: Build script
echo "3. Testing: ./build.sh (should use 3 cores)"
echo "   Command: ./build.sh debug"
echo "   Expected: Uses 3 cores (MAKEFLAGS override)"
echo ""

# Test 4: Make
echo "4. Testing: make build (should use 3 cores)"
echo "   Command: make build"
echo "   Expected: Uses 3 cores (Makefile override)"
echo ""

echo "To monitor CPU usage during build:"
echo "- Run: top (or another traditional process monitor) in another terminal"
echo "- Watch CPU usage percentage"
echo "- 3 cores ≈ 18.75% max CPU usage (3/16)"
echo "- 16 cores ≈ 100% max CPU usage"
echo ""

echo "Run this script and then execute builds to verify core usage!"
