# Lelap Absensi Mobile

Aplikasi mobile Flutter untuk karyawan Lelap Mom Baby Care Salatiga.

## Fitur

- Login karyawan dengan email dan password.
- Beranda status absensi hari ini.
- Absen masuk dan pulang.
- GPS wajib aktif.
- Validasi radius kantor dari backend.
- Mode Homecare saat di luar radius kantor.
- Foto selfie dari kamera saja.
- Watermark otomatis pada foto.
- Kirim latitude, longitude, alamat, device ID, GPS accuracy, dan indikasi mock location.
- Riwayat absensi.
- Jadwal/shift pribadi.
- Profil dan logout.

## Menjalankan

Pastikan backend berjalan:

```powershell
cd "C:\Users\user\Documents\lelap absen\backend"
npm start
```

Install dependency Flutter:

```powershell
cd "C:\Users\user\Documents\lelap absen\mobile\lelap_absensi"
flutter pub get
flutter run
```

Default API base URL:

```text
http://10.0.2.2:3000
```

Untuk HP fisik, ubah `ApiConfig.defaultBaseUrl` di `lib/main.dart` menjadi IP komputer/server, misalnya:

```dart
static const defaultBaseUrl = 'http://192.168.1.10:3000';
```

Untuk production:

```dart
static const defaultBaseUrl = 'https://lelap.web.id';
```

## Akun Karyawan Seed

- `sari@lelap.web.id` / `Karyawan123!`
- `dinda@lelap.web.id` / `Karyawan123!`
- `maya@lelap.web.id` / `Karyawan123!`
- `rina@lelap.web.id` / `Karyawan123!`

## Permission Android

Tambahkan permission ini pada `android/app/src/main/AndroidManifest.xml` setelah menjalankan `flutter create .` jika belum ada:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## Permission iOS

Tambahkan ini pada `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Aplikasi membutuhkan kamera untuk foto selfie absensi.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Aplikasi membutuhkan lokasi untuk validasi absensi.</string>
```

## Catatan

Source ini dibuat manual karena Flutter SDK belum tersedia di environment saat pembuatan. Jalankan `flutter create .` dari folder ini bila folder `android/` dan `ios/` belum ada, lalu pertahankan file `lib/main.dart` dan `pubspec.yaml`.
