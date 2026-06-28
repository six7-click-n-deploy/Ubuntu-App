#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Provisioning Script für Golden Ubuntu 26.04 Image
# - Basistools + Python + Node.js
# - Linux-Lernverzeichnis unter /etc/skel/linux-kurs/ (wird in jeden neuen
#   Home-Ordner kopiert)
# - Idempotent, reproduzierbar, CI/CD-tauglich
# -----------------------------------------------------------------------------

NODE_MAJOR=24

echo "Warte auf cloud-init (sofern vorhanden)..."
cloud-init status --wait || true

echo "System aktualisieren..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "Installiere minimale Basis-Tools..."
sudo apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  gnupg \
  tree

echo "Installiere Python..."
sudo apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv

echo "Füge NodeSource Repository für Node.js ${NODE_MAJOR}.x hinzu..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "Types: deb
URIs: https://deb.nodesource.com/node_${NODE_MAJOR}.x/
Suites: nodistro
Components: main
Signed-By: /etc/apt/keyrings/nodesource.gpg" \
  | sudo tee /etc/apt/sources.list.d/nodesource.sources > /dev/null

echo "Installiere Node.js..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends nodejs

# SSH-Passwort-Authentifizierung vorbereiten (für cloud-init)
# Drop-in unter sshd_config.d/ — überschreibt nicht die Hauptdatei
echo "Bereite SSH für Passwort-Auth vor..."
sudo mkdir -p /etc/ssh/sshd_config.d
printf 'PasswordAuthentication yes\n' \
  | sudo tee /etc/ssh/sshd_config.d/60-password-auth.conf > /dev/null

# =============================================================================
# Linux-Lernverzeichnis
# Wird unter /etc/skel/ abgelegt -> automatisch in jeden neuen Home-Ordner
# =============================================================================
echo "Erstelle Linux-Lernverzeichnis..."

KURS_DIR="/etc/skel/linux-kurs"
sudo mkdir -p \
  "${KURS_DIR}/uebungen/01-navigation" \
  "${KURS_DIR}/uebungen/02-dateien" \
  "${KURS_DIR}/uebungen/03-berechtigungen" \
  "${KURS_DIR}/uebungen/04-prozesse" \
  "${KURS_DIR}/uebungen/05-textverarbeitung" \
  "${KURS_DIR}/beispieldaten"

# --- Kurzanleitung (LIES_MICH.txt) ------------------------------------------
sudo tee "${KURS_DIR}/LIES_MICH.txt" > /dev/null << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    LINUX TERMINAL – KURZANLEITUNG                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

Willkommen auf deiner Linux-VM!
Dieses Verzeichnis enthält Übungsaufgaben und eine Kurzreferenz der wichtigsten
Terminal-Befehle. Starte mit den Aufgaben in den Unterordnern.

  tree linux-kurs/          → Zeigt die komplette Verzeichnisstruktur
  cat linux-kurs/LIES_MICH.txt   → Diese Datei erneut lesen

──────────────────────────────────────────────────────────────────────────────
 1. NAVIGATION
──────────────────────────────────────────────────────────────────────────────
  pwd                  Aktuelles Verzeichnis anzeigen (Print Working Directory)
  ls                   Verzeichnisinhalt auflisten
  ls -la               Ausführliche Liste inkl. versteckter Dateien
  cd ordner/           In Ordner wechseln
  cd ..                Eine Ebene höher gehen
  cd ~                 In Home-Verzeichnis wechseln
  cd -                 Zum vorherigen Verzeichnis zurück

──────────────────────────────────────────────────────────────────────────────
 2. DATEIEN & VERZEICHNISSE
──────────────────────────────────────────────────────────────────────────────
  touch datei.txt      Leere Datei erstellen
  mkdir ordner         Neuen Ordner anlegen
  mkdir -p a/b/c       Verschachtelte Ordner auf einmal anlegen
  cp quelle ziel       Datei kopieren
  cp -r ordner/ ziel/  Ordner rekursiv kopieren
  mv alt neu           Datei verschieben oder umbenennen
  rm datei.txt         Datei löschen
  rm -r ordner/        Ordner mit Inhalt löschen (Vorsicht!)
  tree                 Verzeichnisbaum grafisch anzeigen

──────────────────────────────────────────────────────────────────────────────
 3. DATEIINHALT LESEN & BEARBEITEN
──────────────────────────────────────────────────────────────────────────────
  cat datei.txt        Gesamten Inhalt ausgeben
  less datei.txt       Inhalt seitenweise lesen (q = beenden)
  head -n 10 datei     Erste 10 Zeilen
  tail -n 10 datei     Letzte 10 Zeilen
  nano datei.txt       Einfacher Text-Editor (Strg+O = speichern, Strg+X = beenden)
  grep "wort" datei    Nach "wort" in einer Datei suchen
  grep -r "wort" .     Rekursiv im aktuellen Verzeichnis suchen

──────────────────────────────────────────────────────────────────────────────
 4. BERECHTIGUNGEN
──────────────────────────────────────────────────────────────────────────────
  ls -l                Rechte anzeigen (rwxrwxrwx = owner/group/others)
  chmod 755 datei      Rechte setzen (7=rwx, 5=rx, 4=r)
  chmod +x skript.sh   Ausführbar machen
  chown user datei     Besitzer ändern
  sudo befehl          Befehl als Administrator ausführen

  Rechte-Kurzübersicht:
    r = lesen (4)
    w = schreiben (2)
    x = ausführen (1)
    Beispiel: 644 = rw-r--r--  (owner lesen+schreiben, rest nur lesen)

──────────────────────────────────────────────────────────────────────────────
 5. PROZESSE
──────────────────────────────────────────────────────────────────────────────
  ps aux               Alle laufenden Prozesse
  top                  Live-Prozessübersicht (q = beenden)
  htop                 Verbesserte Prozessübersicht (falls installiert)
  kill PID             Prozess beenden (PID aus ps oder top ablesen)
  kill -9 PID          Prozess sofort erzwingen zu beenden
  befehl &             Befehl im Hintergrund starten
  jobs                 Hintergrundprozesse anzeigen

──────────────────────────────────────────────────────────────────────────────
 6. TEXTVERARBEITUNG & UMLEITUNGEN
──────────────────────────────────────────────────────────────────────────────
  echo "Text"          Text ausgeben
  echo "Text" > a.txt  Text in Datei schreiben (überschreibt)
  echo "Text" >> a.txt Text an Datei anhängen
  befehl | grep "x"   Ausgabe filtern (Pipe)
  wc -l datei.txt      Zeilen zählen
  sort datei.txt       Zeilen sortieren
  uniq datei.txt       Duplikate entfernen (nach sort verwenden)
  cut -d',' -f1 datei  Spalte aus CSV ausschneiden

──────────────────────────────────────────────────────────────────────────────
 7. NETZWERK & SYSTEM
──────────────────────────────────────────────────────────────────────────────
  ip a                 Netzwerkinterfaces und IP-Adressen
  ping google.com      Verbindungstest
  curl https://...     URL abrufen
  df -h                Festplattennutzung
  du -sh ordner/       Ordnergröße
  free -h              RAM-Nutzung
  uname -a             Systeminformation
  uptime               Laufzeit und Auslastung
  history              Befehlshistorie
  which python3        Pfad eines Programms finden
  journalctl -n 50     Letzte 50 Systemlog-Einträge (ersetzt /var/log/syslog)

──────────────────────────────────────────────────────────────────────────────
 8. HILFE BEKOMMEN
──────────────────────────────────────────────────────────────────────────────
  man ls               Handbuchseite für "ls" (q = beenden)
  ls --help            Kurzhilfe für die meisten Befehle
  info befehl          Ausführlichere Dokumentation

──────────────────────────────────────────────────────────────────────────────
 Tipp: Nutze TAB für Autovervollständigung und Pfeiltasten für Befehlshistorie!
──────────────────────────────────────────────────────────────────────────────
EOF

# --- Übung 01: Navigation ----------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/01-navigation/aufgaben.txt" > /dev/null << 'EOF'
ÜBUNG 1 – Navigation im Dateisystem
====================================

Aufgabe 1: Wo bin ich?
  Finde heraus, in welchem Verzeichnis du dich gerade befindest.
  Befehl: pwd

Aufgabe 2: Was ist hier drin?
  Liste den Inhalt deines Home-Verzeichnisses auf — auch versteckte Dateien.
  Befehl: ls -la ~

Aufgabe 3: Wechseln
  a) Wechsle in das Verzeichnis /tmp
  b) Gehe zurück in dein Home-Verzeichnis
  c) Wechsle in das linux-kurs-Verzeichnis ohne den vollen Pfad zu schreiben
  Befehl: cd, cd ~, cd -

Aufgabe 4: Verzeichnisbaum
  Zeige die Struktur des linux-kurs-Verzeichnisses als Baum an.
  Befehl: tree ~/linux-kurs

Aufgabe 5: Pfade erkunden
  Was steht in /etc? Was in /var/log?
  Befehl: ls /etc | head -20
EOF

# --- Übung 02: Dateien -------------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/02-dateien/aufgaben.txt" > /dev/null << 'EOF'
ÜBUNG 2 – Dateien und Verzeichnisse
=====================================

Aufgabe 1: Erstellen
  Erstelle im Ordner uebungen/02-dateien/:
  a) Eine leere Datei namens "notizen.txt"
  b) Einen Unterordner "entwuerfe"
  c) Die Ordnerstruktur "projekte/web/css" in einem Befehl
  Befehle: touch, mkdir, mkdir -p

Aufgabe 2: Inhalt schreiben
  Schreibe "Mein erster Linux-Text" in notizen.txt.
  Hänge eine zweite Zeile "Zweite Zeile" an die Datei an.
  Befehle: echo "..." > datei, echo "..." >> datei

Aufgabe 3: Lesen
  Zeige den Inhalt von notizen.txt an.
  Befehl: cat notizen.txt

Aufgabe 4: Kopieren und verschieben
  a) Kopiere notizen.txt als "notizen_backup.txt" in den Ordner "entwuerfe/"
  b) Benenne notizen.txt in "meine_notizen.txt" um
  Befehle: cp, mv

Aufgabe 5: Aufräumen
  Lösche den Ordner "entwuerfe/" mitsamt Inhalt.
  Befehl: rm -r entwuerfe/
  ACHTUNG: rm löscht unwiderruflich — kein Papierkorb!
EOF

# --- Übung 03: Berechtigungen ------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/03-berechtigungen/aufgaben.txt" > /dev/null << 'EOF'
ÜBUNG 3 – Berechtigungen
==========================

Aufgabe 1: Rechte lesen
  Erstelle eine Datei "test.txt" und zeige ihre Berechtigungen an.
  Was bedeuten die Zeichen in der ersten Spalte?
  Befehl: touch test.txt && ls -l test.txt

Aufgabe 2: Rechte setzen (numerisch)
  Setze die Rechte auf:
  a) 644 — owner lesen+schreiben, alle anderen nur lesen
  b) 600 — nur der owner darf lesen und schreiben
  c) 755 — owner alles, alle anderen lesen+ausführen
  Befehl: chmod 644 test.txt

Aufgabe 3: Skript ausführbar machen
  Erstelle eine Datei "hallo.sh" mit folgendem Inhalt:
    #!/bin/bash
    echo "Hallo, $(whoami)!"
  Mache sie ausführbar und starte sie.
  Befehle: nano hallo.sh, chmod +x hallo.sh, ./hallo.sh

Aufgabe 4: Bedeutung von rwx
  Erkläre in eigenen Worten:
  -rw-r--r-- 1 alice alice 42 Jan 1 12:00 geheim.txt
  - Wer darf lesen?
  - Wer darf schreiben?
  - Wer darf ausführen?
EOF

# --- Übung 04: Prozesse ------------------------------------------------------
sudo tee "${KURS_DIR}/uebungen/04-prozesse/aufgaben.txt" > /dev/null << 'EOF'
ÜBUNG 4 – Prozesse
===================

Aufgabe 1: Prozesse anzeigen
  Zeige alle laufenden Prozesse an.
  Filtere die Ausgabe: Zeige nur Python-Prozesse.
  Befehle: ps aux, ps aux | grep python

Aufgabe 2: Live-Übersicht
  Öffne die Live-Prozessübersicht. Welcher Prozess verbraucht am meisten CPU?
  Befehl: top  (q zum Beenden)

Aufgabe 3: Hintergrundprozess
  Starte folgenden Befehl im Hintergrund:
    sleep 60 &
  Zeige deine Hintergrundprozesse an.
  Finde die PID des sleep-Prozesses und beende ihn.
  Befehle: jobs, ps aux | grep sleep, kill <PID>

Aufgabe 4: Prozess-Info
  Finde heraus, welche PID deine aktuelle Shell hat.
  Befehl: echo $$
EOF

# --- Übung 05: Textverarbeitung ----------------------------------------------
sudo tee "${KURS_DIR}/uebungen/05-textverarbeitung/aufgaben.txt" > /dev/null << 'EOF'
ÜBUNG 5 – Textverarbeitung und Pipes
======================================

Aufgabe 1: Suchen mit grep
  Suche in /etc/passwd nach deinem Benutzernamen.
  Befehl: grep "$(whoami)" /etc/passwd

Aufgabe 2: Zeilen zählen
  Wie viele Benutzer gibt es auf dem System?
  Befehl: wc -l /etc/passwd

Aufgabe 3: Sortieren
  Erstelle eine Datei "zahlen.txt" mit folgenden Zeilen:
    42
    7
    100
    3
    55
  Sortiere die Datei numerisch.
  Befehle: nano zahlen.txt, sort -n zahlen.txt

Aufgabe 4: Pipes kombinieren
  Zeige die 5 größten Dateien im /var/log-Verzeichnis.
  Befehl: du -sh /var/log/* 2>/dev/null | sort -rh | head -5

Aufgabe 5: Text ersetzen mit sed
  Ersetze in einer Textdatei das Wort "alt" durch "neu".
  Befehl: sed 's/alt/neu/g' datei.txt

Aufgabe 6 (Bonus): Log-Analyse
  Zeige die letzten 100 Systemlog-Einträge und filtere nach "error".
  Befehl: journalctl -n 100 | grep -i "error"
EOF

# --- Beispieldaten -----------------------------------------------------------
sudo tee "${KURS_DIR}/beispieldaten/studenten.csv" > /dev/null << 'EOF'
name,matrikelnummer,studiengang,semester
Alice Müller,1234567,Informatik,3
Bob Schmidt,2345678,Wirtschaftsinformatik,5
Carol Weber,3456789,Informatik,1
David Bauer,4567890,Medieninformatik,7
Eva Koch,5678901,Informatik,3
Frank Meier,6789012,Wirtschaftsinformatik,2
EOF

sudo tee "${KURS_DIR}/beispieldaten/server.log" > /dev/null << 'EOF'
2024-01-15 08:12:03 INFO  Server gestartet auf Port 8080
2024-01-15 08:12:05 INFO  Datenbank verbunden
2024-01-15 08:15:22 INFO  GET /api/users 200 OK
2024-01-15 08:16:01 ERROR Verbindung zu Cache-Server fehlgeschlagen
2024-01-15 08:16:02 WARN  Fallback auf direkten DB-Zugriff
2024-01-15 08:20:44 INFO  POST /api/login 200 OK
2024-01-15 08:31:10 INFO  GET /api/data 200 OK
2024-01-15 08:45:00 ERROR Timeout bei Anfrage /api/report nach 30s
2024-01-15 09:00:00 INFO  Backup gestartet
2024-01-15 09:00:45 INFO  Backup abgeschlossen (1.2 GB)
2024-01-15 09:15:33 WARN  Hohe CPU-Auslastung: 87%
2024-01-15 09:20:11 INFO  GET /api/users 200 OK
2024-01-15 09:45:00 ERROR Datenbankabfrage fehlgeschlagen: timeout
2024-01-15 10:00:00 INFO  System läuft normal
EOF

sudo tee "${KURS_DIR}/beispieldaten/README.txt" > /dev/null << 'EOF'
Beispieldaten für Terminal-Übungen
====================================

studenten.csv  – CSV-Datei mit Studierenden (für Aufgaben mit cut, grep, sort)
server.log     – Simuliertes Server-Log   (für Aufgaben mit grep, tail, wc)

Probiere zum Beispiel:
  grep "ERROR" server.log
  cut -d',' -f1,3 studenten.csv
  grep "Informatik" studenten.csv | wc -l
  sort -t',' -k4 -n studenten.csv
EOF

# Lesbar für alle, schreiben nur root
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

echo "Prüfe Versionen..."
python3 --version
pip3 --version
node --version
npm --version

echo "Cleanup: apt-Cache & Listen entfernen..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Setze machine-id zurück..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id || true

echo "Provisioning abgeschlossen."