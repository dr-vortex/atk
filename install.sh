#!/bin/bash

echo "Installing ATK"
exedir="$HOME/.local/bin"
mkdir -p "$exedir"
cp "atk.sh" "$exedir/atk"
chmod +x "$exedir/atk"

echo atk --version
