#!/bin/bash

echo "🦀 Rust System Monitor - Performance Benchmark"
echo "=============================================="
echo

# Binary sizes
echo "📦 Binary Sizes:"
echo "Full TUI Monitor: $(du -h target/release/rust-monitor | cut -f1)"
echo "Simple Monitor:   $(du -h target/release/simple-monitor | cut -f1)"
echo

# Compare with htop if available
if command -v htop &> /dev/null; then
    echo "📊 Memory Usage Comparison:"
    echo "Running memory usage test..."
    
    # Start our simple monitor in background
    ./target/release/simple-monitor &
    RUST_PID=$!
    sleep 2
    
    # Get memory usage of our monitor
    RUST_MEM=$(ps -o rss= -p $RUST_PID 2>/dev/null | tr -d ' ')
    
    # Kill our monitor
    kill $RUST_PID 2>/dev/null
    
    if [ ! -z "$RUST_MEM" ]; then
        echo "Rust Monitor:     ${RUST_MEM} KB"
        
        # Compare with htop if running
        HTOP_PID=$(pgrep htop | head -1)
        if [ ! -z "$HTOP_PID" ]; then
            HTOP_MEM=$(ps -o rss= -p $HTOP_PID | tr -d ' ')
            echo "htop (running):   ${HTOP_MEM} KB"
            
            if [ $RUST_MEM -lt $HTOP_MEM ]; then
                SAVINGS=$((HTOP_MEM - RUST_MEM))
                PERCENT=$((SAVINGS * 100 / HTOP_MEM))
                echo "💚 Memory savings: ${SAVINGS} KB (${PERCENT}% less than htop)"
            fi
        fi
    fi
else
    echo "htop not found for comparison"
fi

echo
echo "🚀 Performance Features:"
echo "✓ Zero-cost abstractions"
echo "✓ Memory-safe without garbage collection"
echo "✓ Compiled binary (no interpreter overhead)"
echo "✓ Optimized system calls"
echo "✓ Minimal runtime dependencies"
echo
echo "🎯 Use Cases:"
echo "• Production server monitoring"
echo "• Resource-constrained environments"
echo "• Real-time system analysis"
echo "• Development environment monitoring"
