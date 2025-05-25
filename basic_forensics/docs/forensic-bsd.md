# 🛡️ BSD Security Forensics Runbook

## 📖 Overview

This runbook provides a comprehensive step-by-step guide to investigating a suspected compromise on a BSD system (FreeBSD, OpenBSD, macOS) using built-in tools. It is distro-agnostic, non-destructive, and compatible with default BSD utilities.

---

## ⚙️ Phase 1: Initial Triage

### ✅ Check System Uptime and Logins

```sh
uptime
who
w
```

### ✅ Active Network Connections

```sh
sockstat -4 -l
netstat -an
```

### ✅ Running Processes (Top CPU/Memory)

```sh
ps aux | sort -nrk 3 | head    # CPU
ps aux | sort -nrk 4 | head    # Memory
top -o cpu
```

### ✅ Services and Daemons

```sh
cat /etc/rc.conf
service -e
```

---

## 🧾 Phase 2: Log Analysis

### ✅ Authentication Logs

```sh
less /var/log/auth.log
grep -Ei 'sshd|login|failed|refused' /var/log/auth.log
```

### ✅ Sudo Usage

```sh
grep sudo /var/log/auth.log
```

### ✅ Login History

```sh
last
lastlogin
```

### ✅ Failed Logins

```sh
grep -i 'failed' /var/log/auth.log
```

---

## 🧱 Phase 3: File System Integrity

### ✅ Recently Modified Files

```sh
find / -type f -mtime -3 2>/dev/null
```

### ✅ SUID/SGID Files

```sh
find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null
```

### ✅ Hidden Files and Temporary Binaries

```sh
find /tmp /var/tmp /dev /run -type f -perm +111
find / -name ".*" 2>/dev/null
```

### ✅ Core Binary Checksums

```sh
sha256 /bin/ls /bin/ps /usr/bin/netstat
```

---

## 🔐 Phase 4: User & SSH Audit

### ✅ List All Users

```sh
cat /etc/passwd
```

### ✅ Detect UID 0 Users

```sh
awk -F: '$3 == 0 {print $1}' /etc/passwd
```

### ✅ SSH Authorized Keys

```sh
cat /home/*/.ssh/authorized_keys
cat /root/.ssh/authorized_keys
```

---

## ⏰ Phase 5: Scheduled Jobs

### ✅ User Crontabs

```sh
for user in $(cut -f1 -d: /etc/passwd); do crontab -l -u "$user" 2>/dev/null; done
```

### ✅ System Cron Jobs

```sh
cat /etc/crontab
ls -al /etc/cron.d/ /etc/periodic/
```

---

## 📦 Phase 6: Persistent Services

### ✅ rc.conf-Defined Services

```sh
cat /etc/rc.conf
service -e
```

### ✅ Local Service Scripts

```sh
ls /usr/local/etc/rc.d/
ls /etc/rc.d/
```

---

## 📜 Phase 7: Command History

```sh
cat ~/.history
cat /home/*/.history
cat ~/.bash_history
cat ~/.zsh_history
```

### ✅ Check if History Logging Is Disabled

```sh
env | grep HIST
```

---

## 📡 Phase 8: Network Logs

### ✅ Packet Filter Logs

```sh
tcpdump -n -e -ttt -i pflog0
grep -i 'block\|pass' /var/log/messages
```

---

## 🧩 Phase 9: PAM Investigation

### ✅ PAM Events

```sh
grep -Ei 'pam_unix|pam_exec|authentication' /var/log/auth.log
```

### ✅ Check for Malicious pam_exec

```sh
grep -r pam_exec /etc/pam.d/
```

---

## 💽 Phase 10: Evidence Collection

### ✅ Disk Imaging

```sh
dd if=/dev/ada0 of=/mnt/usb/disk_image.img bs=1m status=progress
```

Use `geom disk list` to verify device names.

---

## 🔁 Phase 11: Containment

### ✅ Disconnect Network Interfaces

```sh
ifconfig em0 down
ifconfig igb0 down
```

### ✅ Disable Suspicious Users

```sh
pw lock <username>
```

### ✅ Kill Malicious Processes

```sh
kill -9 <PID>
```

---

## ☑️ Bonus: Audit Enhancements

### ✅ Enable and View Audit Logs

```sh
praudit /var/audit/*
```

Edit `/etc/security/audit_control` to configure.

---

## 🧠 Final Note

> “Logs can lie. History can vanish. But file changes, user behavior, and failed logins always leave shadows. You just have to shine the right light.”

Always keep logs backed up, enable auditing, and rebuild compromised systems from trusted sources.
