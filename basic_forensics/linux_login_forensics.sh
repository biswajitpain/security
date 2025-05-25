#!/bin/bash

# linux_login_forensics.sh
# Full Linux forensic script: login analysis, UID 0, SSH keys, history, crons
# Run as root for full access
# Author: The friend you called in your system's final hours

echo "------------------------------------------------------------"
echo "🧠 Linux Login & User Forensics Script"
echo "------------------------------------------------------------"

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "❌ Must be run as root!"
  exit 1
fi

# Set up safe copies of sensitive files
TMP_WTMP="/tmp/wtmp_copy"
TMP_BTMP="/tmp/btmp_copy"
cp /var/log/wtmp "$TMP_WTMP" 2>/dev/null
cp /var/log/btmp "$TMP_BTMP" 2>/dev/null

# Output directory
OUTPUT_DIR="./login_forensics_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Currently logged-in users
echo -e "\n🧍 Currently Logged In Users:" | tee -a "$OUTPUT_DIR/live_users.txt"
who | tee -a "$OUTPUT_DIR/live_users.txt"

# All user accounts
echo -e "\n👤 All User Accounts:" | tee "$OUTPUT_DIR/user_list.txt"
cut -d: -f1,3,4,6,7 /etc/passwd | column -s: -t | tee -a "$OUTPUT_DIR/user_list.txt"

# Users with UID 0 (privileged)
echo -e "\n🔐 Users with UID 0:" | tee "$OUTPUT_DIR/uid0_users.txt"
awk -F: '($3 == 0) { print $1 " -> UID 0" }' /etc/passwd | tee -a "$OUTPUT_DIR/uid0_users.txt"

# Suspicious login shells
echo -e "\n🐚 Users with suspicious login shells:" | tee "$OUTPUT_DIR/suspicious_shells.txt"
grep -Ev '/(false|nologin|shutdown)' /etc/passwd | awk -F: '($7 != "/bin/bash" && $7 != "/bin/sh") {print $1,$7}' | tee -a "$OUTPUT_DIR/suspicious_shells.txt"

# SSH authorized keys
echo -e "\n🔑 SSH Authorized Keys per User:" | tee "$OUTPUT_DIR/ssh_keys.txt"
for u in $(cut -d: -f1 /etc/passwd); do
  home=$(eval echo ~$u)
  keyfile="$home/.ssh/authorized_keys"
  if [[ -f "$keyfile" ]]; then
    echo -e "\n[$u] $keyfile:" | tee -a "$OUTPUT_DIR/ssh_keys.txt"
    cat "$keyfile" | tee -a "$OUTPUT_DIR/ssh_keys.txt"
  fi
done

# Last logins
echo -e "\n🧭 Last Login Times (lastlog):" | tee "$OUTPUT_DIR/lastlog.txt"
lastlog | tee -a "$OUTPUT_DIR/lastlog.txt"

# Login history
echo -e "\n📜 Login History (wtmp):" | tee "$OUTPUT_DIR/login_history.txt"
last -f "$TMP_WTMP" | tee -a "$OUTPUT_DIR/login_history.txt"

# Failed login attempts
echo -e "\n❌ Failed Login Attempts (btmp):" | tee "$OUTPUT_DIR/failed_logins.txt"
lastb -f "$TMP_BTMP" | tee -a "$OUTPUT_DIR/failed_logins.txt"

# Repeated failed login IPs
echo -e "\n🚨 Repeated Failed Login IPs:" | tee "$OUTPUT_DIR/repeated_failed_ips.txt"
lastb -f "$TMP_BTMP" | awk '{print $3}' | grep -E '^[0-9]+\.[0-9]+' | sort | uniq -c | sort -nr | awk '$1 > 3 {print $2 " -> " $1 " failed attempts"}' | tee -a "$OUTPUT_DIR/repeated_failed_ips.txt"

# Crontabs
echo -e "\n⏰ Crontabs for All Users:" | tee "$OUTPUT_DIR/crontabs.txt"
for u in $(cut -f1 -d: /etc/passwd); do
  echo -e "\n[$u]" | tee -a "$OUTPUT_DIR/crontabs.txt"
  crontab -l -u "$u" 2>/dev/null | tee -a "$OUTPUT_DIR/crontabs.txt"
done

# System-wide cron
echo -e "\n🗂️ System-wide Cron Jobs:" | tee "$OUTPUT_DIR/system_cron.txt"
for d in /etc/cron.* /etc/crontab /etc/cron.d/*; do
  [[ -f "$d" || -d "$d" ]] && echo -e "\n$d:" && cat "$d" 2>/dev/null
done | tee -a "$OUTPUT_DIR/system_cron.txt"

# User shell history
echo -e "\n📖 User Shell History Files (bash/zsh):" | tee "$OUTPUT_DIR/user_histories.txt"
for home in /home/* /root; do
  for hist in "$home"/.bash_history "$home"/.zsh_history; do
    if [[ -f "$hist" ]]; then
      echo -e "\n[$hist]:" | tee -a "$OUTPUT_DIR/user_histories.txt"
      cat "$hist" | tee -a "$OUTPUT_DIR/user_histories.txt"
    fi
  done
done

# Cleanup
rm -f "$TMP_WTMP" "$TMP_BTMP"

echo -e "\n✅ Forensic data collection complete."
echo "📁 All results saved in: $OUTPUT_DIR"
