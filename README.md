# System Audit Tool

System Audit Tool — инструмент для базового security и инфраструктурного аудита Linux-систем.  
Подходит для быстрых проверок серверов, VPS и рабочих машин.

Написан на **Python + Bash**, ориентирован на автоматизацию и расширяемость.

---

## Возможности

- Сбор системной информации
- Проверка SSH, firewall, пользователей, сервисов
- Отдельные security-проверки по секциям
- Security Verdict: `OK / WARN / FAIL`
- Экспорт отчётов:
  - TXT
  - Markdown
  - JSON

---

## Требования

- Linux
- Python 3.8+
- sudo/root-доступ

---

### Быстрая установка (1 команда)

```bash
curl -fsSL https://raw.githubusercontent.com/DevvIlya/system_audit/main/install.sh | bash

## Запуск

```bash
sudo system-audit
```
