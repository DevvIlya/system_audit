#!/usr/bin/env bash
set -e

echo "[*] System Audit Tool installation started"

INSTALL_DIR="$(pwd)/system-audit"
VENV_DIR="$INSTALL_DIR/venv"
BIN_PATH="$INSTALL_DIR/system-audit"
REPO_URL="https://github.com/DevvIlya/system_audit.git"

# Проверка зависимостей
for cmd in git python3; do
    if ! command -v $cmd &>/dev/null; then
        echo "[!] $cmd not found. Install it first."
        exit 1
    fi
done

echo "[*] Installing to $INSTALL_DIR"

# Клонируем или обновляем репозиторий
if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Создаем виртуальное окружение
if [ ! -d "$VENV_DIR" ]; then
    echo "[*] Creating virtual environment"
    python3 -m venv "$VENV_DIR"
fi

# Устанавливаем зависимости
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r requirements.txt

# Создаем CLI-скрипт
cat > "$BIN_PATH" <<EOF
#!/usr/bin/env bash
exec "$VENV_DIR/bin/python" "$INSTALL_DIR/audit.py" "\$@"
EOF
chmod +x "$BIN_PATH"

# Проверяем config.yaml
if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
    echo "[*] Creating default config.yaml"
    cat > "$INSTALL_DIR/config.yaml" <<EOC
report_dir: reports
report_prefix: report
check_firewall: true
check_ssh: true
check_fail2ban: true
bash_script: ./utils.sh
EOC
fi

# Создаем папку reports
mkdir -p "$INSTALL_DIR/reports"

echo
echo "[+] Installation completed successfully!"
echo "Run: $BIN_PATH"
echo "Or add $INSTALL_DIR to your PATH to run as 'system-audit'"
echo
echo "[✓] Testing installation:"
"$BIN_PATH" --help || true
