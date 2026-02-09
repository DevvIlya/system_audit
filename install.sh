#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/DevvIlya/system_audit.git"
INSTALL_DIR="/opt/system-audit"
VENV_DIR="$INSTALL_DIR/venv"
BIN_PATH="/usr/local/bin/system-audit"

echo "[*] System Audit Tool installation started"

# checks
command -v git >/dev/null || { echo "[!] git not found"; exit 1; }
command -v python3 >/dev/null || { echo "[!] python3 not found"; exit 1; }

echo "[*] Installing to $INSTALL_DIR"
sudo rm -rf "$INSTALL_DIR"
sudo git clone "$REPO_URL" "$INSTALL_DIR"

cd "$INSTALL_DIR"

echo "[*] Creating virtual environment"
sudo python3 -m venv "$VENV_DIR"

echo "[*] Installing dependencies"
sudo "$VENV_DIR/bin/pip" install --upgrade pip
sudo "$VENV_DIR/bin/pip" install -r requirements.txt


echo "[*] Creating CLI command: system-audit"
sudo tee "$BIN_PATH" > /dev/null <<EOF
#!/usr/bin/env bash
exec $VENV_DIR/bin/python $INSTALL_DIR/audit.py "\$@"
EOF

sudo chmod +x "$BIN_PATH"

echo "[+] Installation completed successfully"
echo "Run: system-audit"

echo
echo "[✓] system-audit installed:"
which system-audit
system-audit --help || true
