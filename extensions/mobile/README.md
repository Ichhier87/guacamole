# Guacamole Mobile Keyboard Enhancement

Diese Extension verbessert die Nutzung von Guacamole auf mobilen Geräten, insbesondere auf Android und iOS.

## Features

### 1. **Floating Keyboard Button**
- Ein immer sichtbarer Button (⌨️) in der unteren rechten Ecke
- Ermöglicht schnellen Zugriff auf die virtuelle Tastatur
- Touch-optimiert mit großem, gut erreichbarem Button

### 2. **Optimierte Tastatur-Darstellung**
- Vergrößerte Tasten für bessere Touch-Bedienung (min. 44x44px)
- Verbesserte Sichtbarkeit der Modifier-Tasten (Ctrl, Alt, Shift)
- Anpassbare Höhe der Tastatur durch Drag-Gesture
- Festes Positioning am unteren Bildschirmrand

### 3. **Touch-Optimierungen**
- Verhindert ungewolltes Zoomen beim Doppeltippen
- Vergrößerte Touch-Targets für alle Buttons und Menüs
- Touch-freundliche Scrollbars
- Doppelklick auf Display öffnet Tastatur

### 4. **Mobile-First UI**
- Responsive Design für Smartphones und Tablets
- Anpassungen für Portrait und Landscape Modi
- Optimierungen für PWA (Progressive Web App) Modus
- HTTP/2 Support für schnelleres Laden

### 5. **Keyboard Fallback**
- Falls die Guacamole OSK nicht verfügbar ist, wird ein natives Input-Feld genutzt
- Automatische Weiterleitung von Tastatureingaben an den Remote-Desktop

## Verwendung auf Android

1. Öffne Guacamole in deinem Browser (Chrome, Firefox, etc.)
2. Verbinde dich mit einem Remote-Desktop
3. **Tastatur öffnen:**
   - Tippe auf den ⌨️ Button unten rechts, ODER
   - Doppeltippe auf den Remote-Desktop Bereich, ODER
   - Öffne das Guacamole-Menü und wähle "Keyboard"

4. **Tastatur anpassen:**
   - Ziehe den Griff oben auf der Tastatur um die Höhe anzupassen
   - Die Tastatur bleibt am unteren Rand fixiert

## Installation

Die Extension wird automatisch über nginx injiziert. Nach dem Docker-Neustart ist sie sofort verfügbar.

## Technische Details

### Dateien
- `mobile-keyboard.css` - Styling für mobile UI-Verbesserungen
- `mobile-keyboard.js` - JavaScript für Keyboard-Handling und Touch-Events
- `inject.html` - HTML-Snippet für manuelle Integration (falls benötigt)

### nginx Integration
Die Files werden über nginx als statische Ressourcen bereitgestellt unter `/mobile-extensions/` und automatisch in die Guacamole-HTML-Seite injiziert mittels `sub_filter`.

### Kompatibilität
- ✅ Android (Chrome, Firefox, Samsung Internet)
- ✅ iOS/iPadOS (Safari, Chrome)
- ✅ Tablets (Android & iPad)
- ✅ Desktop-Browser (keine negativen Auswirkungen)

## Debugging

Die Extension loggt ihre Aktivitäten in der Browser-Console. Öffne die Developer Tools (F12) und schaue in die Console für Debug-Informationen:

```
[Mobile Keyboard] Script loaded
[Mobile Keyboard] Initializing mobile keyboard enhancements
[Mobile Keyboard] Floating keyboard button created
[Mobile Keyboard] Toggle keyboard requested
```

## Anpassungen

### CSS Anpassungen
Bearbeite `mobile-keyboard.css` um Styling anzupassen:
- Button-Größe: `#mobile-keyboard-toggle` → `width` / `height`
- Button-Position: `#mobile-keyboard-toggle` → `bottom` / `right`
- Tastatur-Höhe: `.guac-keyboard` → `max-height`
- Key-Größe: `.guac-keyboard .key` → `min-height` / `min-width`

### JavaScript Anpassungen
Bearbeite `mobile-keyboard.js` um Verhalten anzupassen:
- Auto-Keyboard-Trigger (aktuell: Doppelklick)
- Tastatur-Toggle-Methoden
- Touch-Event-Handling

## Deaktivierung

Um die Extension zu deaktivieren:
1. Entferne die Volume-Mount-Zeile aus `docker-compose.yml`:
   ```yaml
   - ./extensions/mobile:/etc/nginx/mobile-extensions:ro
   ```
2. Entferne die `sub_filter` Zeilen aus `nginx/conf.d/default.conf`
3. Starte Container neu: `docker-compose restart nginx`

## Troubleshooting

### Tastatur erscheint nicht
- Prüfe Browser-Console auf Fehler
- Stelle sicher dass JavaScript aktiviert ist
- Teste manuell: Öffne Guacamole-Menü und suche nach "Keyboard" Button

### Button nicht sichtbar
- Prüfe ob CSS-Datei geladen wird: Browser DevTools → Network → `/mobile-extensions/mobile-keyboard.css`
- Prüfe CSS-Overrides: Browser DevTools → Elements → Suche nach `#mobile-keyboard-toggle`

### Touch-Gesten funktionieren nicht
- Prüfe ob JavaScript-Datei geladen wird
- Prüfe Browser-Console auf JavaScript-Fehler
- Teste in einem anderen Browser

## Performance Impact

Die Extension hat minimalen Performance-Impact:
- CSS: ~3KB (nicht komprimiert)
- JavaScript: ~7KB (nicht komprimiert)
- Keine zusätzlichen HTTP-Requests nach initialem Laden (1 Tag Cache)
- Keine Auswirkungen auf Desktop-Nutzung

## Support

Bei Problemen:
1. Prüfe Browser-Console auf Fehler
2. Prüfe nginx logs: `docker logs nginx`
3. Prüfe ob Files korrekt gemountet sind: `docker exec nginx ls -la /etc/nginx/mobile-extensions/`
