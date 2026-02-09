#!/usr/bin/env python3
import os
import subprocess
import platform
import psutil
from datetime import datetime
import yaml
import json
from tabulate import tabulate

from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
CONFIG_FILE = BASE_DIR / "config.yaml"

CONFIG_FILE = "config.yaml"
with open(CONFIG_FILE) as f:
    config = yaml.safe_load(f)

REPORT_DIR = config.get("report_dir", "reports")
os.makedirs(REPORT_DIR, exist_ok=True)
BASH_SCRIPT = config.get("bash_script", "./utils.sh")

def run_bash():
    result = subprocess.run(["bash", BASH_SCRIPT], capture_output=True, text=True)
    return result.stdout + result.stderr

def parse_sections(raw_output: str) -> dict:
    sections = {}
    current = None
    for line in raw_output.splitlines():
        if line.startswith("==="):
            current = line.replace("=", "").strip()
            sections[current] = []
        elif current and line.strip() != "":
            sections[current].append(line)
    return sections

def security_verdict(sections: dict) -> list:
    verdicts = []

    # Firewall
    if config.get("check_firewall"):
        fw = "\n".join(sections.get("FIREWALL", [])).lower()
        if "активен" in fw or "status: active" in fw:
            verdicts.append(("Firewall", "OK"))
        else:
            verdicts.append(("Firewall", "WARN"))

    # SSH
    if config.get("check_ssh"):
        ssh_lines = sections.get("SSH", [])
        ssh_text = "\n".join(ssh_lines)
        if "Root login test: ALLOWED" in ssh_text:
            verdicts.append(("SSH Root Login", "FAIL"))
        else:
            verdicts.append(("SSH Root Login", "OK"))

        if "PasswordAuthentication yes" in ssh_text:
            verdicts.append(("SSH Password Auth", "WARN"))
        else:
            verdicts.append(("SSH Password Auth", "OK"))

    # Fail2Ban
    if config.get("check_fail2ban"):
        services = "\n".join(sections.get("SERVICES", []))
        verdicts.append(("Fail2Ban", "OK" if "fail2ban" in services.lower() else "WARN"))

    return verdicts

def system_info() -> list:
    info = [
        ["OS", platform.system()],
        ["OS Version", platform.version()],
        ["CPU", platform.processor()],
        ["RAM", f"{round(psutil.virtual_memory().total / (1024**3),2)} GB"],
        ["Disk", f"{round(psutil.disk_usage('/').total / (1024**3),2)} GB"],
        ["Users", ", ".join(u.name for u in psutil.users())]
    ]
    return info

def build_json_report(timestamp, verdicts, sys_info, sections):
    return {
        "timestamp": timestamp,
        "verdicts": [{"check": n, "status": s} for n, s in verdicts],
        "system_info": {k: v for k, v in sys_info},
        "checks": sections
    }

def generate_report():
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    raw_bash = run_bash()
    sections = parse_sections(raw_bash)
    verdicts = security_verdict(sections)
    sys_info = system_info()

    # Таблицы
    txt_sys = tabulate(sys_info, headers=["Property", "Value"], tablefmt="grid")
    md_sys = tabulate(sys_info, headers=["Property", "Value"], tablefmt="github")
    md_verdicts = tabulate(verdicts, headers=["Check", "Status"], tablefmt="github")

    # Пути
    txt_path = f"{REPORT_DIR}/{config.get('report_prefix','report')}_{timestamp}.txt"
    md_path = f"{REPORT_DIR}/{config.get('report_prefix','report')}_{timestamp}.md"
    json_path = f"{REPORT_DIR}/{config.get('report_prefix','report')}_{timestamp}.json"

    # TXT
    with open(txt_path, "w") as f:
        f.write(f"System Audit Report — {timestamp}\n\n")
        f.write("=== SYSTEM INFO ===\n")
        f.write(txt_sys + "\n\n")
        f.write("=== SECURITY VERDICT ===\n")
        for name, status in verdicts:
            f.write(f"{name}: {status}\n")
        for section, content in sections.items():
            f.write(f"\n=== {section} ===\n")
            f.write("\n".join(content) + "\n")

    # Markdown
    with open(md_path, "w") as f:
        f.write(f"# System Audit Report — {timestamp}\n\n")
        f.write("## 🛡 Security Verdict\n\n")
        f.write(md_verdicts + "\n\n")
        f.write("## 🖥 System Info\n\n")
        f.write(md_sys + "\n\n")
        for section, content in sections.items():
            f.write(f"## {section}\n\n```\n")
            f.write("\n".join(content))
            f.write("\n```\n\n")

    # JSON
    json_report = build_json_report(timestamp, verdicts, sys_info, sections)
    with open(json_path, "w") as f:
        json.dump(json_report, f, indent=2)

    print("Reports generated:")
    print(f"- {txt_path}")
    print(f"- {md_path}")
    print(f"- {json_path}")

if __name__ == "__main__":
    generate_report()
