# 🛡️ Linux Security Forensics Runbook

## 📖 Overview

This runbook is a comprehensive step-by-step guide to investigating a suspected compromise or intrusion on a Linux system using built-in tools only. It's designed to be distro-agnostic and non-destructive.

---

## ⚙️ Phase 1: Initial Triage

### ✅ Check System Uptime and Logins

```bash
uptime
who
w
```

### ✅ Active Network Connections

```bash
ss -tulnp
netstat -antup
lsof -i
```

### ✅ Running Processes

```bash
ps aux --sort=-%cpu
top -n 1
```

### ✅ List Enabled Services

```bash
systemctl list-units --type=service
chkconfig --list  # Legacy systems
```

---

## 🧾 Phase 2: Log Analysis

### ✅ Authentication Logs

```bash
# Ubuntu/Debian
cat /var/log/auth.log

# RHEL/CentOS
cat /var/log/secure

grep "sshd" /var/log/auth.log
grep "Failed password" /var/log/auth.log
```

### ✅ Sudo Usage

```bash
grep sudo /var/log/auth.log
```

### ✅ Login History

```bash
last
lastlog
```

### ✅ Failed Logins (btmp)

```bash
lastb
```

---

## 🧱 Phase 3: File System Integrity

### ✅ Recently Modified Files

```bash
find / -type f -mtime -3 2>/dev/null
```

### ✅ SUID/SGID Files

```bash
find / -perm -4000 -type f 2>/dev/null
```

### ✅ Hidden Files and Temporary Binaries

```bash
find /tmp /var/tmp /dev /run -type f -perm /111
find / -name ".*" 2>/dev/null
```

### ✅ Check Core Binary Integrity

```bash
sha256sum /bin/ls /usr/bin/ps /bin/netstat
```

---

## 🔐 Phase 4: User & SSH Audit

### ✅ List All Users

```bash
cat /etc/passwd
```

### ✅ Detect UID 0 Users

```bash
awk -F: '$3 == 0 {print $1}' /etc/passwd
```

### ✅ Review SSH Keys

```bash
cat /home/*/.ssh/authorized_keys
cat /root/.ssh/authorized_keys
```

---

## ⏰ Phase 5: Scheduled Jobs

### ✅ User Crontabs

```bash
for u in $(cut -f1 -d: /etc/passwd); do crontab -l -u $u; done
```

### ✅ System Cron Jobs

```bash
ls -alh /etc/cron*
cat /etc/crontab
```

---

## 📦 Phase 6: Persistent Services

### ✅ User-installed systemd Services

```bash
find /home/*/.config/systemd/user/ -name "*.service"
cat ~/.config/systemd/user/*.service
```

### ✅ System-wide Unit Files

```bash
systemctl list-units --type=service
cat /etc/systemd/system/*.service
```

---

## 📜 Phase 7: Command History (if available)

```bash
cat ~/.bash_history
cat /home/*/.bash_history
```

Check if history is disabled:

```bash
env | grep HIST
```

---

## 📡 Phase 8: Network Logs

### ✅ Firewall & Kernel Logs

```bash
# Debian
cat /var/log/kern.log

# RHEL
cat /var/log/messages

grep -iE 'DROP|REJECT' /var/log/messages
```

---

## 🧩 Phase 9: PAM (Authentication) Investigation

### ✅ PAM Events

```bash
grep -Ei 'pam_unix|pam_exec|pam_authenticate' /var/log/auth.log
```

### ✅ Detect Malicious PAM Modifications

```bash
grep -r 'pam_exec' /etc/pam.d/
```

---

## 💽 Phase 10: Evidence Collection

### ✅ Disk Imaging (if necessary)

```bash
dd if=/dev/sda of=/mnt/usb/diskimage.dd bs=4M status=progress
```

### ✅ Live Memory (if external tools allowed)

- Use LiME + Volatility (external tools)
- Not natively available on most distros

---

## 🔁 Phase 11: Containment

### ✅ Disconnect System from Network

```bash
ip link set eth0 down
```

### ✅ Lock Suspicious Users

```bash
usermod -L username
```

### ✅ Kill Rogue Processes

```bash
kill -9 <PID>
```

---

## ☑️ Bonus: Audit Enhancements

### ✅ Enable Real-Time Audit Logging

```bash
auditctl -a always,exit -F arch=b64 -S execve -k exec_log
ausearch -k exec_log
```

---

## 🧠 Final Note

> "Logs can lie. History can vanish. But file changes, user behavior, and failed logins always leave shadows. You just have to shine the right light."

Stay sharp, keep logs rotated and backed up, and **rebuild compromised systems** from known-good sources.
