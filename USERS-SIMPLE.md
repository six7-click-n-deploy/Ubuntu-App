# Ubuntu-App Benutzer-System

## 4 Test-Benutzer

Die Ubuntu-App erstellt automatisch 4 Benutzer bei VM-Start:

| Benutzername | Passwort | Berechtigung |
|--------------|----------|--------------|
| `alice` | `hallo123` | sudo |
| `clara` | `test123` | sudo |
| `bob` | `einfach123` | sudo |
| `diana` | `ubuntu123` | sudo |

## SSH-Login

Nach dem VM-Start können Sie sich anmelden:

```bash
# Beispiele
ssh alice@<vm-ip>     # Passwort: hallo123
ssh clara@<vm-ip>     # Passwort: test123
ssh bob@<vm-ip>       # Passwort: einfach123
ssh diana@<vm-ip>     # Passwort: ubuntu123
```

## Deployment

1. **Image erstellen** (einmalig):
```bash
cd Ubuntu-App/packer
packer build template.pkr.hcl
```

2. **VM mit Benutzern deployen**:
```bash
cd ../terraform
terraform apply
```

3. **VM-IP ermitteln**:
```bash
terraform output vm_ip
```

4. **Mit Benutzern verbinden**:
```bash
ssh alice@<vm-ip>
# Passwort eingeben: hallo123
```

## Benutzer-Verwaltung

Alle Benutzer haben sudo-Berechtigung und können:
- Passwörter ändern: `passwd`
- Andere Benutzer verwalten (als sudo)
- SSH-Keys hinzufügen für schlüsselbasierte Authentifizierung

Das System ist für **Tests und Entwicklung** optimiert!
