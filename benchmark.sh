#!/bin/bash
set -euo pipefail

echo "🦀 Lyvoxa - Performance Snapshot"
echo "================================"
echo

# Resolve lyvoxa binary path (prefer target triple path)
candidates=(
  "target/x86_64-unknown-linux-gnu/release/lyvoxa"
  "target/release/lyvoxa"
)
BIN=""
for b in "${candidates[@]}"; do
  if [ -x "$b" ]; then
    BIN="$b"
    break
  fi
done

if [ -z "$BIN" ]; then
  echo "⚠️  lyvoxa binary not found."
  echo "Build first: ./build.sh release"
  exit 1
fi

BYTES=$(stat -c %s "$BIN")
FILE_INFO=$(file "$BIN" | sed 's/.*: //')

echo "📦 Binary Path: $BIN"
echo "📏 Binary Size: $(du -h "$BIN" | cut -f1) (${BYTES} bytes)"
echo "🔎 File Info:   ${FILE_INFO}"
echo

# Optional quick memory probe (runs UI briefly, then terminates)
echo "🧪 Quick Memory Probe (2s run)"
"$BIN" >/dev/null 2>&1 & PID=$!
sleep 2
if RSS_KB=$(ps -o rss= -p "$PID" 2>/dev/null | tr -d ' '); then
  if [ -n "$RSS_KB" ]; then
    echo "RSS: ${RSS_KB} KB"
  else
    echo "RSS: unavailable"
  fi
else
  echo "RSS: unavailable"
fi
kill -TERM "$PID" 2>/dev/null || true
sleep 0.2
kill -KILL "$PID" 2>/dev/null || true
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
