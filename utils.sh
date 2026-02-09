#!/usr/bin/env bash
set -e

echo "=== FIREWALL ==="
if command -v ufw &>/dev/null; then
    if sudo -n ufw status &>/dev/null; then
        sudo ufw status verbose | sed 's/^/  /'
    else
        echo "  ERROR: Для запуска этого сценария требуются права администратора"
    fi
else
    echo "  ufw not installed"
fi

echo ""
echo "=== SSH ==="
SSH_CONFIG_FILE="/etc/ssh/sshd_config"
if [ -f "$SSH_CONFIG_FILE" ]; then
    echo "  Config entries (including commented):"
    grep -E "^(#?PermitRootLogin|#?PasswordAuthentication)" "$SSH_CONFIG_FILE" | sed 's/^/    /'

    # Проверка root login
    SSH_TEST=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@localhost echo OK 2>&1 || true)
    if echo "$SSH_TEST" | grep -q "Permission denied"; then
        echo "  Root login test: DENIED"
    elif echo "$SSH_TEST" | grep -q "OK"; then
        echo "  Root login test: ALLOWED"
    else
        echo "  Root login test: ERROR"
    fi
else
    echo "  SSH config not found"
fi

echo ""
echo "=== SERVICES ==="
CRITICAL_SERVICES=("ssh" "fail2ban" "ufw" "postgresql" "nginx" "apache2")
for svc in "${CRITICAL_SERVICES[@]}"; do
    ACTIVE=$(systemctl is-active $svc 2>/dev/null || echo "inactive")
    STATUS=$(systemctl show -p SubState --value $svc 2>/dev/null || echo "unknown")
    PID=$(systemctl show -p MainPID --value $svc 2>/dev/null || echo 0)
    MEM=$(ps -p $PID -o rss= 2>/dev/null || echo 0)
    CPU=$(ps -p $PID -o %cpu= 2>/dev/null || echo 0)
    echo "$svc | $ACTIVE | $STATUS | PID=$PID | MEM=${MEM}KB | CPU=${CPU}%"
done

echo ""
echo "=== CRON ==="
echo "User $(whoami):"
crontab -l 2>/dev/null | sed 's/^/  /'
echo "Root:"
sudo crontab -l -u root 2>/dev/null | sed 's/^/  /'
for f in /etc/cron.*/*; do
    [ -f "$f" ] && echo "  $f"
done

echo ""
echo "=== USERS ==="
getent passwd | awk -F: '$3>=1000 {print "  "$1}'
echo "Users in sudo group:"
getent group sudo | awk -F: '{print "  "$4}'
awk -F: '($2==""){print "  "$1}' /etc/shadow 2>/dev/null || echo "  None"

echo ""
echo "=== NETWORK ==="
ip -brief addr show up | sed 's/^/  /'
echo "Listening ports and services:"
ss -tulnp | sed 's/^/  /'
