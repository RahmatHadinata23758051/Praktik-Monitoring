# Monitoring App (Realtime MQTT IoT)

Deskripsi singkat
-----------------
Aplikasi Flutter untuk monitoring device IoT secara realtime menggunakan MQTT. Aplikasi ini memiliki fitur: Login/Register (lokal), manajemen device (SQLite), konfigurasi broker MQTT, subscribe ke topik device (data/device/device001..device005), parsing payload JSON, dan deteksi offline.

Fitur utama
-----------
- Login & Register (email + konfirmasi password)
- Tambah / daftar device lokal (SQLite, fallback memory untuk web)
- Dashboard realtime menampilkan data device (heart_rate, temperature, battery)
- Pengaturan broker MQTT (host, port) dan koneksi otomatis
- Subscribe default ke topik: `data/device/device001` .. `data/device/device005`
- Styling and offline detection (temperature/battery rules)

Persyaratan pengembangan
------------------------
- Flutter (direkomendasikan versi stable terbaru). Periksa dengan `flutter --version`.
- Android SDK (untuk build Android). Pastikan `sdk` path sudah benar di `android/local.properties`.
- Untuk build Android release: JDK dan Android NDK (Gradle dapat mengunduh NDK side‑by‑side jika perlu).

Menjalankan aplikasi (development)
---------------------------------
1. Install dependency dan jalankan di Chrome (web):

```powershell
flutter pub get
flutter run -d chrome
```

2. Jalankan di Android emulator/device (debug):

```powershell
flutter pub get
flutter run -d <device-id>
```

Build untuk distribusi
----------------------
- Build Web (release):

```powershell
flutter clean
flutter pub get
flutter build web --release
# hasil: build/web/
Compress-Archive -Path build/web/* -DestinationPath build/web-build.zip
```

- Build Android APK (release):

```powershell
flutter clean
flutter pub get
flutter build apk --release
# hasil: build/app/outputs/flutter-apk/app-release.apk
```

- Build Android App Bundle (AAB):

```powershell
flutter build appbundle --release
# hasil: build/app/outputs/bundle/release/app-release.aab
```

- Build Windows (release):

```powershell
flutter build windows --release
# hasil: build/windows/runner/Release/<app>.exe
Compress-Archive -Path build/windows/runner/Release/* -DestinationPath build/windows-build.zip
```

Masalah build umum & solusi cepat
---------------------------------
- NDK korup saat build Android: hapus folder NDK yang rusak lalu build ulang agar Gradle mengunduh ulang.

```powershell
Remove-Item -Recurse -Force 'C:\Users\user\AppData\Local\Android\sdk\ndk\28.2.13676358'
flutter clean
flutter pub get
flutter build apk --release
```

- Error `dart:html` saat build non-web: proyek sudah disesuaikan untuk menghindari import `dart:html` pada build Android/Windows (conditional import factory sudah diterapkan).

Konfigurasi MQTT
-----------------
- Default broker: `broker.emqx.io` (host dapat diubah di Settings dalam aplikasi).
- Topik default: `data/device/device001`..`data/device/device005`.
- Payload JSON yang diharapkan:

```json
{
	"device_id": "005",
	"heart_rate": 74,
	"temperature": 37.6,
	"battery": 56
}
```

Lokasi database (SQLite) dan data local
----------------------------------------
- Android emulator/device (debuggable app): `/data/data/<package_name>/databases/monitoring.db`
- iOS simulator: `~/Library/Developer/CoreSimulator/Devices/<device-id>/data/Containers/Data/Application/<app-id>/Documents/` (file DB di dalam folder databases)
- Windows: path yang dikembalikan oleh `path_provider` (biasanya `%LOCALAPPDATA%\<appName>`)
- Web: `sqflite` tidak didukung; aplikasi menggunakan fallback in-memory untuk web (data tidak persisten setelah reload).

Contoh mengekspor DB dari emulator (PowerShell):

```powershell
adb shell run-as com.example.monitoring cat /data/data/com.example.monitoring/databases/monitoring.db > C:\temp\monitoring.db
```

Debug & logging
---------------
- Di Dashboard ada tombol `MQTT Logs` (ikon Wi‑Fi) untuk melihat log koneksi, subscribe, dan pesan yang diterima.
- Jika pesan tidak muncul di UI, buka MQTT Logs untuk melihat apakah pesan diterima dan apakah parsing JSON berhasil.

Keamanan & catatan produksi
---------------------------
- Saat ini autentikasi disimpan lokal menggunakan `SharedPreferences`. Ini cukup untuk tugas/demo, tetapi bukan aman untuk produksi. Untuk deployment nyata:
	- Gunakan backend auth (OAuth/JWT) atau setidaknya simpan hash password dan gunakan Android Keystore untuk kunci sensitif.
	- Jangan menyimpan password plaintext di SharedPreferences.

- Jika hendak mengunggah ke Play Store: buat keystore signing dan konfig `android/app/build.gradle.kts` untuk signing release.

Struktur penting proyek
----------------------
- `lib/main.dart` — entry point, provider dan routing.
- `lib/services/mqtt_service.dart` — manajemen koneksi MQTT, parsing payload, notify listeners.
- `lib/services/db_helper.dart` — helper SQLite + fallback web memory.
- `lib/services/auth_service.dart` — register/login (SharedPreferences).
- `lib/pages/` — tampilan: `login_page.dart`, `register_page.dart`, `dashboard_page.dart`, `devices_page.dart`, `mqtt_settings_page.dart`.
- `lib/widgets/device_card.dart` — kartu UI device (styling temperature/battery).
