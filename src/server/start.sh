#!/bin/sh
# Paradise IDE - Start Server
set -e

cd "$(dirname "$0")"

echo "Paradise IDE Server"
echo "==================="

# Create venv if missing
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate venv
. .venv/bin/activate

# Install deps
echo "Installing dependencies..."
pip install -q -r requirements.txt

echo ""
echo "Starting server on ws://0.0.0.0:8765"
echo "REST API: http://localhost:8765"
echo ""

python3 server.py
