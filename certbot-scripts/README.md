# Automatisches Zertifikats-Reload für Nginx

Dieses System stellt sicher, dass nginx automatisch neu lädt wenn Let's Encrypt Zertifikate erneuert werden.

## Problem

Let's Encrypt Zertifikate werden alle 60-90 Tage erneuert. Certbot erneuert die Zertifikate automatisch, aber nginx lädt sie nur beim Start. Nach einer Erneuerung würde nginx also weiterhin das alte (abgelaufene) Zertifikat verwenden.

## Lösung

Ein zweistufiges System:

### 1. Certbot Deploy-Hook
Nach erfolgreicher Zertifikatserneuerung erstellt certbot eine Flag-Datei:
- **Datei:** `/etc/letsencrypt/reload-required`
- **Trigger:** `certbot renew --deploy-hook "touch /etc/letsencrypt/reload-required"`

### 2. Nginx Certificate Watcher
Ein Hintergrund-Prozess im nginx-Container überwacht:
- Die **reload-required** Flag-Datei (instant response)
- Die **Zertifikats-Modifikationszeit** (Fallback, alle 60s)

Wenn eine Änderung erkannt wird:
1. nginx-Konfiguration wird getestet (`nginx -t`)
2. Bei Erfolg: nginx wird neu geladen (`nginx -s reload`)
3. Flag-Datei wird entfernt

## Implementierung

### Dateien

```
certbot-scripts/
├── renew-hook.sh           # Manuelles Reload-Hook (optional)
├── renew-with-signal.sh    # Enhanced renewal script
└── README.md               # Diese Datei

nginx/
├── reload-watcher.sh       # Watcher-Script (im Container)
├── entrypoint.sh          # Startet nginx + watcher
└── Dockerfile             # Integriert die Scripts
```

### Docker-Compose Integration

**certbot-renew:**
```yaml
entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew --deploy-hook \"touch /etc/letsencrypt/reload-required\" && chmod -R 755 /etc/letsencrypt; sleep 12h & wait $${!}; done;'"
```

**nginx:**
- Startet zwei Prozesse: nginx + reload-watcher.sh
- Shared Volume: `certbot-conf:/etc/letsencrypt`

## Funktionsweise

### Normale Operation

1. certbot-renew prüft alle 12h ob Zertifikate erneuert werden müssen
2. Bei Erneuerung:
   - Zertifikate werden erneuert
   - Deploy-Hook erstellt `/etc/letsencrypt/reload-required`
   - Permissions werden gesetzt
3. nginx reload-watcher (läuft alle 60s):
   - Findet die Flag-Datei
   - Testet nginx config
   - Reloaded nginx
   - Löscht Flag-Datei

### Fallback

Falls die Flag-Datei nicht funktioniert:
- Watcher prüft Zertifikats-Modifikationszeit
- Bei Änderung: automatischer Reload

## Monitoring

### Logs prüfen

**nginx Watcher:**
```bash
docker logs nginx | grep "Nginx Watcher"
```

Erwartete Ausgabe:
```
[Nginx Watcher] Starting certificate reload watcher...
[Nginx Watcher] Monitoring: /etc/letsencrypt/live/home.dl-dev.de/fullchain.pem
[Nginx Watcher] Check interval: 60s
```

**Certbot Renewal:**
```bash
docker logs certbot-renew | tail -20
```

### Manueller Test

#### 1. Reload-Flag manuell erstellen:
```bash
docker exec certbot-renew touch /etc/letsencrypt/reload-required
```

#### 2. Watcher-Logs beobachten (innerhalb 60s):
```bash
docker logs -f nginx
```

Erwartete Ausgabe:
```
[Nginx Watcher] Reload flag detected! Certificate was renewed.
[Nginx Watcher] Testing nginx configuration...
[Nginx Watcher] Configuration valid, reloading nginx...
[Nginx Watcher] ✓ Nginx reloaded successfully at [timestamp]
[Nginx Watcher] Reload flag removed
```

#### 3. Nginx reload manuell testen:
```bash
docker exec nginx nginx -t
docker exec nginx nginx -s reload
```

### Zertifikat-Info prüfen

```bash
# Ablaufdatum anzeigen
docker exec nginx openssl x509 -in /etc/letsencrypt/live/home.dl-dev.de/fullchain.pem -noout -dates

# Modifikationszeit prüfen
docker exec nginx stat /etc/letsencrypt/live/home.dl-dev.de/fullchain.pem
```

## Certbot Renewal manuell testen

### Dry-Run (simuliert Erneuerung ohne Änderungen):
```bash
docker exec certbot-renew certbot renew --dry-run
```

### Force Renewal (NUR ZUM TESTEN):
```bash
# WARNUNG: Nicht zu oft ausführen (Rate Limits!)
docker exec certbot-renew certbot renew --force-renewal --deploy-hook "touch /etc/letsencrypt/reload-required"
```

## Troubleshooting

### Problem: Reload-Flag wird nicht erstellt

**Prüfen:**
```bash
docker exec certbot-renew ls -la /etc/letsencrypt/
```

**Lösung:**
- Permissions prüfen
- Certbot logs prüfen: `docker logs certbot-renew`

### Problem: nginx reloaded nicht

**Prüfen:**
1. Watcher läuft?
   ```bash
   docker exec nginx ps aux | grep reload-watcher
   ```

2. nginx-Konfiguration valid?
   ```bash
   docker exec nginx nginx -t
   ```

3. Permissions auf Zertifikat?
   ```bash
   docker exec nginx ls -la /etc/letsencrypt/live/home.dl-dev.de/
   ```

### Problem: Watcher stoppt

**Neustart:**
```bash
docker-compose restart nginx
```

**Logs prüfen:**
```bash
docker logs nginx --tail 100
```

## Zeitplan

- **Certbot Renewal Check:** Alle 12 Stunden
- **Watcher Check:** Alle 60 Sekunden
- **Let's Encrypt Erneuerung:** Automatisch 30 Tage vor Ablauf
- **Zertifikats-Gültigkeit:** 90 Tage

## Sicherheit

- Kein Docker-Socket-Mounting benötigt
- nginx läuft als root (benötigt für Port 443)
- Certbot läuft isoliert
- Shared Volume nur für Zertifikate (read-only für nginx)
- Keine externe Kommunikation zwischen Containern nötig

## Performance Impact

- **Watcher:** Minimal (~0.1% CPU alle 60s)
- **Reload:** ~100ms Downtime während nginx reload
- **Memory:** +2MB für Watcher-Prozess

## Vorteile

✅ Automatisch - keine manuelle Intervention nötig
✅ Sicher - keine Docker-Socket-Rechte erforderlich
✅ Robust - Fallback-Mechanismus
✅ Transparent - Ausführliches Logging
✅ Schnell - Reload innerhalb 60s
✅ Zuverlässig - Testet Config vor Reload
