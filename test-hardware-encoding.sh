#!/bin/bash
# Hardware-Video-Encoding Test für Odroid M1 (Rockchip RK3568)

echo "=== Rockchip RK3568 Hardware-Encoding Test ==="
echo ""

echo "1. Prüfe Hardware-Video-Geräte..."
echo "   /dev/dri (DRM/KMS):"
ls -la /dev/dri 2>/dev/null || echo "   ❌ Nicht gefunden"

echo ""
echo "   /dev/mpp_service (Rockchip MPP):"
ls -la /dev/mpp_service 2>/dev/null || echo "   ❌ Nicht gefunden (normal wenn MPP nicht geladen)"

echo ""
echo "   /dev/video* (V4L2):"
ls -la /dev/video* 2>/dev/null || echo "   ❌ Nicht gefunden"

echo ""
echo "2. Prüfe ob guacd Container Zugriff hat..."
docker exec guacd ls -la /dev/dri 2>/dev/null && echo "   ✓ /dev/dri verfügbar" || echo "   ❌ /dev/dri NICHT verfügbar"
docker exec guacd ls -la /dev/video0 2>/dev/null && echo "   ✓ /dev/video0 verfügbar" || echo "   ❌ /dev/video0 NICHT verfügbar"

echo ""
echo "3. Prüfe FFmpeg in guacd..."
if docker exec guacd which ffmpeg >/dev/null 2>&1; then
    echo "   ✓ FFmpeg gefunden"
    echo ""
    echo "   FFmpeg-Version:"
    docker exec guacd ffmpeg -version 2>/dev/null | head -1
    echo ""
    echo "   Verfügbare Hardware-Encoder:"
    docker exec guacd ffmpeg -hide_banner -encoders 2>/dev/null | grep -i "h264\|hevc\|265\|264\|v4l2\|rkmpp" || echo "   Keine Hardware-Encoder gefunden"
else
    echo "   ❌ FFmpeg NICHT gefunden in guacd"
fi

echo ""
echo "4. Prüfe libavcodec in guacd..."
docker exec guacd find /usr/lib -name "libavcodec*" 2>/dev/null | head -3 && echo "   ✓ libavcodec gefunden" || echo "   ❌ libavcodec NICHT gefunden"

echo ""
echo "5. Prüfe Rockchip-spezifische Libraries..."
docker exec guacd find /usr/lib -name "*mpp*" -o -name "*rockchip*" 2>/dev/null | head -5 || echo "   ❌ Keine Rockchip-Libraries gefunden"

echo ""
echo "6. Teste H.264-Encoding (falls FFmpeg verfügbar)..."
if docker exec guacd which ffmpeg >/dev/null 2>&1; then
    echo "   Software-Encoding Test (libx264):"
    docker exec guacd timeout 5 ffmpeg -f lavfi -i testsrc=duration=1:size=1280x720:rate=30 -c:v libx264 -preset ultrafast -f null - 2>&1 | grep -i "fps\|error" || echo "   Test abgeschlossen"

    echo ""
    echo "   Hardware-Encoding Test (h264_v4l2m2m falls verfügbar):"
    docker exec guacd timeout 5 ffmpeg -f lavfi -i testsrc=duration=1:size=1280x720:rate=30 -c:v h264_v4l2m2m -f null - 2>&1 | grep -i "fps\|error" || echo "   v4l2m2m nicht verfügbar"
fi

echo ""
echo "7. Prüfe guacd-Build-Konfiguration..."
docker exec guacd /opt/guacamole/sbin/guacd --version 2>&1

echo ""
echo "=== ZUSAMMENFASSUNG ==="
echo ""
echo "Wenn Hardware-Encoding funktioniert, solltest du sehen:"
echo "  ✓ /dev/dri und /dev/video* Geräte"
echo "  ✓ FFmpeg mit h264_v4l2m2m oder h264_rkmpp Encoder"
echo "  ✓ libavcodec in guacd"
echo ""
echo "Falls NICHT verfügbar:"
echo "  → guacd muss mit FFmpeg+Rockchip-Support neu kompiliert werden"
echo "  → Oder RDP-Server (Windows) nutzt eigenes H.264 (auch gut!)"
echo ""
