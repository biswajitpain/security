#!/bin/bash

# linux_network_pam_forensics.sh
# Collects SSH, PAM, firewall, and system auth logs

OUTPUT_DIR="./network_pam_forensics_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "------------------------------------------------------------"
echo "🌐 Network & PAM Forensics Collection"
echo "------------------------------------------------------------"

# Detect distro to pick correct log files
if grep -qi "ubuntu\|debian" /etc/os-release; then
  AUTH_LOG="/var/log/auth.log"
  KERN_LOG="/var/log/kern.log"
elif grep -qi "centos\|rhel\|fedora\|almalinux" /etc/os-release; then
  AUTH_LOG="/var/log/secure"
  KERN_LOG="/var/log/messages"
else
  AUTH_LOG="/var/log/auth.log"
  KERN_LOG="/var/log/messages"
fi

# SSH Logs
echo -e "\n🔐 SSH Logins and Failures:" | tee "$OUTPUT_DIR/ssh_logs.txt"
grep -Ei 'sshd|accepted|failed|disconnect|auth' "$AUTH_LOG" | tee -a "$OUTPUT_DIR/ssh_logs.txt"

# PAM Logs
echo -e "\n🧩 PAM Authentication Events:" | tee "$OUTPUT_DIR/pam_logs.txt"
grep -Ei 'pam_unix|pam_exec|pam_authenticate|authentication failure' "$AUTH_LOG" | tee -a "$OUTPUT_DIR/pam_logs.txt"

# Custom PAM modules
echo -e "\n🕵️ Suspicious pam_exec Hooks:" | tee "$OUTPUT_DIR/pam_exec.txt"
grep -r 'pam_exec' /etc/pam.d/ | tee -a "$OUTPUT_DIR/pam_exec.txt"

# Netstat
echo -e "\n📡 Network Sockets (ss -tulnp):" | tee "$OUTPUT_DIR/network_ports.txt"
ss -tulnp | tee -a "$OUTPUT_DIR/network_ports.txt"

# lsof network
echo -e "\n🌍 Open Network Files (lsof -i):" | tee "$OUTPUT_DIR/lsof_net.txt"
lsof -i | tee -a "$OUTPUT_DIR/lsof_net.txt"

# Firewall Logs
echo -e "\n🔥 Firewall Activity (DROP/REJECT):" | tee "$OUTPUT_DIR/firewall_logs.txt"
grep -iE 'DROP|REJECT' "$KERN_LOG" | tee -a "$OUTPUT_DIR/firewall_logs.txt"

# Active SSHD service logs
echo -e "\n📜 systemd journal for SSH:" | tee "$OUTPUT_DIR/systemd_ssh.txt"
journalctl -u ssh --no-pager --since "2 days ago" 2>/dev/null | tee -a "$OUTPUT_DIR/systemd_ssh.txt"

echo -e "\n✅ All logs collected in: $OUTPUT_DIR"
