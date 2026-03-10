<#
.SINOPSIS
    Script untuk memicu crash pada perangkat Android via ADB (langsung tanpa menu).
.DESCRIPTION
    Menjalankan serangkaian perintah ADB yang dapat menyebabkan aplikasi atau sistem crash.
    Pastikan ADB sudah terinstal dan perangkat terhubung dengan USB debugging aktif.
#>

# --- Konfigurasi ---
$JumlahEventMonkey = 5000   # Semakin besar, semakin berat
# ------------------

Write-Host "🚀 Memulai proses crash Android..." -ForegroundColor Cyan

# 1. Cek keberadaan ADB
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ADB tidak ditemukan. Pastikan Android SDK platform-tools ada di PATH." -ForegroundColor Red
    exit 1
}

# 2. Cek perangkat terhubung
$devices = adb devices | Select-String -Pattern "device$" -NotMatch "List"
if (-not $devices) {
    Write-Host "❌ Tidak ada perangkat Android terdeteksi. Periksa koneksi USB dan aktifkan USB debugging." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Perangkat terdeteksi. Mulai mengeksekusi perintah crash..." -ForegroundColor Green

# 3. Matikan paksa System UI (sering menyebabkan tampilan hang/restart)
Write-Host "   • Mematikan System UI..." -ForegroundColor Yellow
adb shell am force-stop com.android.systemui

# 4. Kirim intent dengan data sangat besar ke beberapa aplikasi umum (bisa memicu force close)
Write-Host "   • Mengirim data invalid ke aplikasi..." -ForegroundColor Yellow
$paketAplikasi = @("com.android.settings", "com.android.chrome", "com.google.android.apps.maps")
foreach ($pkg in $paketAplikasi) {
    adb shell am start -n "$pkg/.MainActivity" --es "payload" ("A" * 200000) 2>$null
}

# 5. Jalankan Monkey (event acak) pada seluruh sistem
Write-Host "   • Menjalankan Monkey dengan $JumlahEventMonkey event acak..." -ForegroundColor Yellow
adb shell monkey -v $JumlahEventMonkey 2>$null

# 6. Jika perangkat di-root, coba picu kernel crash
$rootCheck = adb shell 'su -c "id"' 2>$null
if ($rootCheck -like "*uid=0*") {
    Write-Host "   • Perangkat di-root, mencoba kernel crash..." -ForegroundColor Yellow
    adb shell 'su -c "echo c > /proc/sysrq-trigger"' 2>$null
} else {
    Write-Host "   • Perangkat tidak di-root, lewati kernel crash." -ForegroundColor DarkYellow
}

Write-Host "✅ Proses selesai. Perangkat mungkin akan mengalami crash, restart, atau menjadi tidak responsif." -ForegroundColor Green
