#!/usr/bin/env bash
set -e

echo "[*] System Audit Tool installation started"

INSTALL_DIR="/opt/system-audit"
VENV_DIR="$INSTALL_DIR/venv"
BIN_PATH="/usr/local/bin/system-audit"

# Проверка Python
if ! command -v python3 &>/dev/null; then
    echo "[!] Python3 not found"
    exit 1
fi

echo "[*] Creating install directory: $INSTALL_DIR"
sudo mkdir -p $INSTALL_DIR

echo "[*] Copying project files"
sudo cp -r audit.py utils config.yaml requirements.txt $INSTALL_DIR

# Virtualenv
if [ ! -d "$VENV_DIR" ]; then
    echo "[*] Creating virtual environment"
    sudo python3 -m venv $VENV_DIR
fi

echo "[*] Installing Python dependencies"
sudo $VENV_DIR/bin/pip install --upgrade pip
sudo $VENV_DIR/bin/pip install -r $INSTALL_DIR/requirements.txt

echo "[*] Creating CLI command"
sudo tee $BIN_PATH > /dev/null <<EOF
#!/usr/bin/env bash
exec $VENV_DIR/bin/python $INSTALL_DIR/audit.py "\$@"
EOF

sudo chmod +x $BIN_PATH

echo "[+] Installation completed successfully"
echo "Run: sudo system-audit"
