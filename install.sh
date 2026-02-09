#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/DevvIlya/system_audit.git"
INSTALL_DIR="/opt/system-audit"
VENV_DIR="$INSTALL_DIR/venv"
BIN_PATH="/usr/local/bin/system-audit"

echo "[*] System Audit Tool installation started"
echo "[*] Installing to $INSTALL_DIR"

# Проверка git и python
for cmd in git python3; do
    if ! command -v $cmd &>/dev/null; then
        echo "[!] $cmd not found. Please install it first."
        exit 1
    fi
done

# Клонируем репозиторий
sudo rm -rf "$INSTALL_DIR"
sudo git clone "$REPO_URL" "$INSTALL_DIR"

# Виртуальное окружение
echo "[*] Creating virtual environment"
sudo python3 -m venv "$VENV_DIR"

# Установка зависимостей
echo "[*] Installing Python dependencies"
sudo "$VENV_DIR/bin/pip" install --upgrade pip
sudo "$VENV_DIR/bin/pip" install -r "$INSTALL_DIR/requirements.txt"

# Создаём CLI команду с абсолютными путями
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
