#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Provisioning script for Golden Ubuntu 26.04 image
# - Base tools + Python + Node.js
# - Linux course directory at /etc/skel/linux-kurs/ (copied into every new
#   home directory)
# - Idempotent, reproducible, CI/CD-ready
# -----------------------------------------------------------------------------

NODE_MAJOR=24

echo "Waiting for cloud-init (if present)..."
cloud-init status --wait || true

echo "Updating system..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "Installing minimal base tools..."
sudo apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  gnupg \
  tree

echo "Installing Python..."
sudo apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv

echo "Adding NodeSource repository for Node.js ${NODE_MAJOR}.x..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "Types: deb
URIs: https://deb.nodesource.com/node_${NODE_MAJOR}.x/
Suites: nodistro
Components: main
Signed-By: /etc/apt/keyrings/nodesource.gpg" \
  | sudo tee /etc/apt/sources.list.d/nodesource.sources > /dev/null

echo "Installing Node.js..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends nodejs

# Prepare SSH password authentication (for cloud-init)
# Drop-in under sshd_config.d/ — does not overwrite the main config file
echo "Configuring SSH for password authentication..."
sudo mkdir -p /etc/ssh/sshd_config.d
printf 'PasswordAuthentication yes\n' \
  | sudo tee /etc/ssh/sshd_config.d/60-password-auth.conf > /dev/null

# =============================================================================
# Linux course directory
# Placed under /etc/skel/ -> automatically copied into every new home directory
# =============================================================================
echo "Creating Linux course directory..."

KURS_DIR="/etc/skel/linux-kurs"
sudo mkdir -p \
  "${KURS_DIR}/uebungen/01-navigation" \
  "${KURS_DIR}/uebungen/02-dateien" \
  "${KURS_DIR}/uebungen/03-berechtigungen" \
  "${KURS_DIR}/uebungen/04-prozesse" \
  "${KURS_DIR}/uebungen/05-textverarbeitung" \
  "${KURS_DIR}/beispieldaten"

# --- Quick reference guide (LIES_MICH.txt) ----------------------------------
sudo tee "${KURS_DIR}/LIES_MICH.txt" > /dev/null << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LINUX TERMINAL – QUICK REFERENCE                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

Welcome to your Linux VM!
This directory contains exercises and a quick reference for the most important
terminal commands. Start with the tasks in the subdirectories.

  tree linux-kurs/          → Show the full directory structure
  cat linux-kurs/LIES_MICH.txt   → Read this file again

──────────────────────────────────────────────────────────────────────────────
 1. NAVIGATION
──────────────────────────────────────────────────────────────────────────────
  pwd                  Print current working directory
  ls                   List directory contents
  ls -la               Long listing including hidden files
  cd ordner/           Change into directory
  cd ..                Go up one level
  cd ~                 Go to home directory
  cd -                 Return to previous directory

──────────────────────────────────────────────────────────────────────────────
 2. FILES & DIRECTORIES
──────────────────────────────────────────────────────────────────────────────
  touch datei.txt      Create an empty file
  mkdir ordner         Create a new directory
  mkdir -p a/b/c       Create nested directories at once
  cp quelle ziel       Copy a file
  cp -r ordner/ ziel/  Copy directory recursively
  mv alt neu           Move or rename a file
  rm datei.txt         Delete a file
  rm -r ordner/        Delete directory with contents (caution!)
  tree                 Display directory tree

──────────────────────────────────────────────────────────────────────────────
 3. FILE CONTENT – READ & EDIT
──────────────────────────────────────────────────────────────────────────────
  cat datei.txt        Print entire file contents
  less datei.txt       Read content page by page (q = quit)
  head -n 10 datei     First 10 lines
  tail -n 10 datei     Last 10 lines
  nano datei.txt       Simple text editor (Ctrl+O = save, Ctrl+X = quit)
  grep "wort" datei    Search for "word" in a file
  grep -r "wort" .     Search recursively in current directory

──────────────────────────────────────────────────────────────────────────────
 4. PERMISSIONS
──────────────────────────────────────────────────────────────────────────────
  ls -l                Show permissions (rwxrwxrwx = owner/group/others)
  chmod 755 datei      Set permissions (7=rwx, 5=rx, 4=r)
  chmod +x skript.sh   Make executable
  chown user datei     Change owner
  sudo befehl          Run command as administrator

  Permissions quick reference:
    r = read (4)
    w = write (2)
    x = execute (1)
    Example: 644 = rw-r--r--  (owner read+write, others read-only)

──────────────────────────────────────────────────────────────────────────────
 5. PROCESSES
──────────────────────────────────────────────────────────────────────────────
  ps aux               List all running processes
  top                  Live process overview (q = quit)
  htop                 Enhanced process viewer (if installed)
  kill PID             Terminate process (get PID from ps or top)
  kill -9 PID          Force-kill process immediately
  befehl &             Run command in background
  jobs                 List background jobs

──────────────────────────────────────────────────────────────────────────────
 6. TEXT PROCESSING & REDIRECTIONS
──────────────────────────────────────────────────────────────────────────────
  echo "Text"          Print text
  echo "Text" > a.txt  Write text to file (overwrites)
  echo "Text" >> a.txt Append text to file
  befehl | grep "x"   Filter output (pipe)
  wc -l datei.txt      Count lines
  sort datei.txt       Sort lines
  uniq datei.txt       Remove duplicates (use after sort)
  cut -d',' -f1 datei  Extract column from CSV

──────────────────────────────────────────────────────────────────────────────
 7. NETWORK & SYSTEM
──────────────────────────────────────────────────────────────────────────────
  ip a                 Network interfaces and IP addresses
  ping google.com      Connection test
  curl https://...     Fetch a URL
  df -h                Disk usage
  du -sh ordner/       Directory size
  free -h              RAM usage
  uname -a             System information
  uptime               Uptime and load
  history              Command history
  which python3        Find the path of a program
  journalctl -n 50     Last 50 system log entries (replaces /var/log/syslog)

──────────────────────────────────────────────────────────────────────────────
 8. GETTING HELP
──────────────────────────────────────────────────────────────────────────────
  man ls               Manual page for "ls" (q = quit)
  ls --help            Short help for most commands
  info befehl          More detailed documentation

──────────────────────────────────────────────────────────────────────────────
 Tip: Use TAB for auto-completion and arrow keys for command history!
──────────────────────────────────────────────────────────────────────────────
EOF

# --- Exercise 01: Navigation -------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/01-navigation/aufgaben.txt" > /dev/null << 'EOF'
EXERCISE 1 – Navigating the Filesystem
=======================================

Task 1: Where am I?
  Find out which directory you are currently in.
  Command: pwd

Task 2: What is here?
  List the contents of your home directory — including hidden files.
  Command: ls -la ~

Task 3: Navigating
  a) Change into the /tmp directory
  b) Go back to your home directory
  c) Change into the linux-kurs directory without typing the full path
  Commands: cd, cd ~, cd -

Task 4: Directory tree
  Display the structure of the linux-kurs directory as a tree.
  Command: tree ~/linux-kurs

Task 5: Exploring paths
  What is in /etc? What in /var/log?
  Command: ls /etc | head -20
EOF

# --- Exercise 02: Files ------------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/02-dateien/aufgaben.txt" > /dev/null << 'EOF'
EXERCISE 2 – Files and Directories
=====================================

Task 1: Create
  Create the following inside uebungen/02-dateien/:
  a) An empty file named "notizen.txt"
  b) A subdirectory "entwuerfe"
  c) The directory structure "projekte/web/css" in a single command
  Commands: touch, mkdir, mkdir -p

Task 2: Write content
  Write "My first Linux text" into notizen.txt.
  Append a second line "Second line" to the file.
  Commands: echo "..." > datei, echo "..." >> datei

Task 3: Read
  Display the contents of notizen.txt.
  Command: cat notizen.txt

Task 4: Copy and move
  a) Copy notizen.txt as "notizen_backup.txt" into the "entwuerfe/" directory
  b) Rename notizen.txt to "meine_notizen.txt"
  Commands: cp, mv

Task 5: Clean up
  Delete the "entwuerfe/" directory and all its contents.
  Command: rm -r entwuerfe/
  WARNING: rm deletes permanently — no trash bin!
EOF

# --- Exercise 03: Permissions ------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/03-berechtigungen/aufgaben.txt" > /dev/null << 'EOF'
EXERCISE 3 – Permissions
==========================

Task 1: Read permissions
  Create a file "test.txt" and display its permissions.
  What do the characters in the first column mean?
  Command: touch test.txt && ls -l test.txt

Task 2: Set permissions (numeric)
  Set the permissions to:
  a) 644 — owner read+write, everyone else read-only
  b) 600 — only the owner may read and write
  c) 755 — owner full access, everyone else read+execute
  Command: chmod 644 test.txt

Task 3: Make a script executable
  Create a file "hallo.sh" with the following content:
    #!/bin/bash
    echo "Hello, $(whoami)!"
  Make it executable and run it.
  Commands: nano hallo.sh, chmod +x hallo.sh, ./hallo.sh

Task 4: Meaning of rwx
  Explain in your own words:
  -rw-r--r-- 1 alice alice 42 Jan 1 12:00 secret.txt
  - Who may read?
  - Who may write?
  - Who may execute?
EOF

# --- Exercise 04: Processes --------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/04-prozesse/aufgaben.txt" > /dev/null << 'EOF'
EXERCISE 4 – Processes
===================

Task 1: List processes
  Display all running processes.
  Filter the output: show only Python processes.
  Commands: ps aux, ps aux | grep python

Task 2: Live overview
  Open the live process monitor. Which process uses the most CPU?
  Command: top  (q to quit)

Task 3: Background process
  Start the following command in the background:
    sleep 60 &
  List your background jobs.
  Find the PID of the sleep process and terminate it.
  Commands: jobs, ps aux | grep sleep, kill <PID>

Task 4: Process info
  Find out the PID of your current shell.
  Command: echo $$
EOF

# --- Exercise 05: Text processing --------------------------------------------
sudo tee "${KURS_DIR}/uebungen/05-textverarbeitung/aufgaben.txt" > /dev/null << 'EOF'
EXERCISE 5 – Text Processing and Pipes
======================================

Task 1: Search with grep
  Search /etc/passwd for your username.
  Command: grep "$(whoami)" /etc/passwd

Task 2: Count lines
  How many users are on the system?
  Command: wc -l /etc/passwd

Task 3: Sort
  Create a file "zahlen.txt" with the following lines:
    42
    7
    100
    3
    55
  Sort the file numerically.
  Commands: nano zahlen.txt, sort -n zahlen.txt

Task 4: Combine pipes
  Show the 5 largest files in the /var/log directory.
  Command: du -sh /var/log/* 2>/dev/null | sort -rh | head -5

Task 5: Replace text with sed
  Replace the word "alt" with "neu" in a text file.
  Command: sed 's/alt/neu/g' datei.txt

Task 6 (Bonus): Log analysis
  Show the last 100 system log entries and filter for "error".
  Command: journalctl -n 100 | grep -i "error"
EOF

# --- Sample data -------------------------------------------------------------
sudo tee "${KURS_DIR}/beispieldaten/studenten.csv" > /dev/null << 'EOF'
name,student_id,program,semester
Alice Müller,1234567,Computer Science,3
Bob Schmidt,2345678,Business Informatics,5
Carol Weber,3456789,Computer Science,1
David Bauer,4567890,Media Informatics,7
Eva Koch,5678901,Computer Science,3
Frank Meier,6789012,Business Informatics,2
EOF

sudo tee "${KURS_DIR}/beispieldaten/server.log" > /dev/null << 'EOF'
2024-01-15 08:12:03 INFO  Server started on port 8080
2024-01-15 08:12:05 INFO  Database connected
2024-01-15 08:15:22 INFO  GET /api/users 200 OK
2024-01-15 08:16:01 ERROR Connection to cache server failed
2024-01-15 08:16:02 WARN  Falling back to direct DB access
2024-01-15 08:20:44 INFO  POST /api/login 200 OK
2024-01-15 08:31:10 INFO  GET /api/data 200 OK
2024-01-15 08:45:00 ERROR Timeout on request /api/report after 30s
2024-01-15 09:00:00 INFO  Backup started
2024-01-15 09:00:45 INFO  Backup completed (1.2 GB)
2024-01-15 09:15:33 WARN  High CPU load: 87%
2024-01-15 09:20:11 INFO  GET /api/users 200 OK
2024-01-15 09:45:00 ERROR Database query failed: timeout
2024-01-15 10:00:00 INFO  System running normally
EOF

sudo tee "${KURS_DIR}/beispieldaten/README.txt" > /dev/null << 'EOF'
Sample data for terminal exercises
====================================

studenten.csv  – CSV file with student records (for exercises with cut, grep, sort)
server.log     – Simulated server log        (for exercises with grep, tail, wc)

Try for example:
  grep "ERROR" server.log
  cut -d',' -f1,3 studenten.csv
  grep "Computer Science" studenten.csv | wc -l
  sort -t',' -k4 -n studenten.csv
EOF

# World-readable, root-writable only
sudo chmod -R 755 "${KURS_DIR}"
sudo chmod 644 \
  "${KURS_DIR}/LIES_MICH.txt" \
  "${KURS_DIR}/beispieldaten/studenten.csv" \
  "${KURS_DIR}/beispieldaten/server.log" \
  "${KURS_DIR}/beispieldaten/README.txt" \
  "${KURS_DIR}/uebungen/01-navigation/aufgaben.txt" \
  "${KURS_DIR}/uebungen/02-dateien/aufgaben.txt" \
  "${KURS_DIR}/uebungen/03-berechtigungen/aufgaben.txt" \
  "${KURS_DIR}/uebungen/04-prozesse/aufgaben.txt" \
  "${KURS_DIR}/uebungen/05-textverarbeitung/aufgaben.txt"

echo "Checking versions..."
python3 --version
pip3 --version
node --version
npm --version

echo "Cleanup: removing apt cache and lists..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Resetting machine-id..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id || true

echo "Provisioning complete."
