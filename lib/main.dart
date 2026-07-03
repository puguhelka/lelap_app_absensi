import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const LelapAbsensiApp());
}

class LelapAbsensiApp extends StatelessWidget {
  const LelapAbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lelap Absensi',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════ SPLASH SCREEN ═══════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ApiService _api;
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _auth = AuthService(_api);
    _init();
  }

  Future<void> _init() async {
    await _auth.init();
    if (!mounted) return;
    if (_auth.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(api: _api, auth: _auth),
      ));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => LoginScreen(api: _api, auth: _auth),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lelap', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            Text('Absensi', style: TextStyle(fontSize: 24, color: AppTheme.accentColor)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ LOGIN SCREEN ═══════════════════════

class LoginScreen extends StatefulWidget {
  final ApiService api;
  final AuthService auth;
  const LoginScreen({super.key, required this.api, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (widget.auth.isLoggedIn && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(api: widget.api, auth: widget.auth),
      ));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.auth.login(_emailCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lelap', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  Text('Absensi Karyawan', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', hintText: 'contoh@email.com'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  if (widget.auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(widget.auth.error!, style: const TextStyle(color: AppTheme.dangerColor, fontSize: 14)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.auth.loading ? null : _login,
                      child: widget.auth.loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Masuk'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ HOME SCREEN ═══════════════════════

class HomeScreen extends StatefulWidget {
  final ApiService api;
  final AuthService auth;
  const HomeScreen({super.key, required this.api, required this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  HomeData? _homeData;
  bool _loading = true;
  String? _error;
  DateTime _now = DateTime.now();
  Timer? _timer;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _now = DateTime.now()));
    _loadHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await widget.api.get(ApiConfig.home);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _homeData = HomeData.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Gagal memuat data.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Gagal terhubung ke server.'; _loading = false; });
    }
  }

  void _navigateToCheckIn() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckInScreen(api: widget.api, auth: widget.auth, type: 'check_in'),
    )).then((_) => _loadHome());
  }

  void _navigateToCheckOut() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CheckInScreen(api: widget.api, auth: widget.auth, type: 'check_out'),
    )).then((_) => _loadHome());
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomePage(),
      HistoryScreen(api: widget.api),
      ScheduleScreen(api: widget.api),
      _buildProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.cardBg,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Jadwal'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Lelap Absensi'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHome),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadHome, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHome,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTimeCard(),
                        const SizedBox(height: 16),
                        _buildEmployeeInfo(),
                        const SizedBox(height: 16),
                        _buildAttendanceStatus(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        if (_homeData!.hasCheckIn && !_homeData!.hasCheckOut) ...[
                          const SizedBox(height: 16),
                          _buildHomecareWarning(),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTimeCard() {
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'id');
    final timeStr = DateFormat('HH:mm').format(_now);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Text(timeStr, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200, color: Colors.white)),
          const SizedBox(height: 4),
          Text(formatter.format(_now), style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    final h = _homeData!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(h.employeeName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(h.employeePosition, style: const TextStyle(color: Colors.white60)),
          if (h.shiftName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.white60),
                const SizedBox(width: 6),
                Text('${h.shiftName} (${h.shiftStart ?? "—"} - ${h.shiftEnd ?? "—"})', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceStatus() {
    final h = _homeData!;
    final statusColor = h.hasCheckIn && h.hasCheckOut
        ? AppTheme.successColor
        : h.hasCheckIn
            ? AppTheme.warningColor
            : AppTheme.dangerColor;
    final statusIcon = h.hasCheckIn && h.hasCheckOut
        ? Icons.check_circle
        : h.hasCheckIn
            ? Icons.access_time
            : Icons.cancel;
    final statusText = h.hasCheckIn && h.hasCheckOut
        ? 'Hadir Lengkap'
        : h.hasCheckIn
            ? 'Belum Absen Pulang'
            : 'Belum Absen';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: statusColor)),
              if (h.checkInTime != null) Text('Masuk: ${h.checkInTime}', style: const TextStyle(color: Colors.white60)),
              if (h.checkOutTime != null) Text('Pulang: ${h.checkOutTime}', style: const TextStyle(color: Colors.white60)),
              if (h.isLate) const Text('⚠️ Telat', style: TextStyle(color: AppTheme.warningColor)),
              if (h.isHomecare) const Text('🏠 Homecare', style: TextStyle(color: AppTheme.infoColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _homeData!.hasCheckIn ? null : _navigateToCheckIn,
            icon: const Icon(Icons.login, size: 24),
            label: Text(_homeData!.hasCheckIn ? 'Sudah Absen Masuk' : 'Absen Masuk'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _homeData!.hasCheckIn ? Colors.grey : AppTheme.successColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _homeData!.hasCheckOut ? null : _navigateToCheckOut,
            icon: const Icon(Icons.logout, size: 24),
            label: Text(_homeData!.hasCheckOut ? 'Sudah Absen Pulang' : 'Absen Pulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _homeData!.hasCheckOut ? Colors.grey : AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomecareWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jangan lupa absen pulang sebelum meninggalkan lokasi!',
              style: TextStyle(color: AppTheme.warningColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                (widget.auth.user?.name.isNotEmpty == true ? widget.auth.user!.name[0] : '?'),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.auth.user?.name ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.auth.user?.email ?? '', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                children: [
                  _profileRow('Role', widget.auth.user?.role ?? ''),
                  const Divider(height: 24),
                  _profileRow('Aplikasi', 'Lelap Absensi v0.1.0'),
                  if (widget.auth.user?.phone != null) ...[
                    const Divider(height: 24),
                    _profileRow('Telepon', widget.auth.user!.phone!),
                  ],
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await widget.auth.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api, auth: widget.auth)),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                label: const Text('Keluar', style: TextStyle(color: AppTheme.dangerColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.dangerColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ═══════════════════════ CHECK IN/OUT SCREEN ═══════════════════════

class CheckInScreen extends StatefulWidget {
  final ApiService api;
  final AuthService auth;
  final String type; // 'check_in' or 'check_out'
  const CheckInScreen({super.key, required this.api, required this.auth, required this.type});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _gpsReady = false;
  bool _gpsChecking = true;
  bool _isOutside = false;
  bool _isHomecare = false;
  bool _photoTaken = false;
  bool _submitting = false;
  String? _error;
  double? _latitude;
  double? _longitude;
  String _address = '';
  double? _distance;
  bool _isMock = false;
  String? _deviceId;
  final _homecareAddrCtrl = TextEditingController();
  final _homecareNoteCtrl = TextEditingController();
  File? _photoFile;
  String? _watermarkedPhotoPath;

  @override
  void initState() {
    super.initState();
    _initDeviceId();
    _checkGps();
  }

  @override
  void dispose() {
    _homecareAddrCtrl.dispose();
    _homecareNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _initDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } catch (_) {
      _deviceId = 'unknown';
    }
  }

  Future<void> _checkGps() async {
    setState(() { _gpsChecking = true; _error = null; });

    final hasPermission = await LocationService.checkAndRequestPermission();
    if (!hasPermission) {
      setState(() { _gpsChecking = false; _error = 'GPS tidak aktif. Aktifkan GPS dan izinkan akses lokasi.'; });
      return;
    }

    final pos = await LocationService.getCurrentPosition();
    if (pos == null) {
      setState(() { _gpsChecking = false; _error = 'Gagal mendapatkan lokasi. Coba di area terbuka.'; });
      return;
    }

    _latitude = pos.latitude;
    _longitude = pos.longitude;
    _address = await LocationService.getAddressFromLatLng(pos.latitude, pos.longitude);
    _isMock = LocationService.isMockLocation(pos);

    // Office location (default Lelap Salatiga)
    const officeLat = -7.330000;
    const officeLng = 110.500000;
    _distance = LocationService.calculateDistance(pos.latitude, pos.longitude, officeLat, officeLng);
    final outside = _distance! > 20; // radius 20 meter

    setState(() {
      _gpsReady = true;
      _gpsChecking = false;
      _isOutside = outside;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (photo == null) return;
      _photoFile = File(photo.path);
      _photoTaken = true;
      setState(() {});

      // Add watermark
      await _addWatermark();
    } catch (e) {
      setState(() => _error = 'Gagal mengambil foto.');
    }
  }

  Future<void> _addWatermark() async {
    if (_photoFile == null) return;
    try {
      final imageBytes = await _photoFile!.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      final now = DateTime.now();
      final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);
      final timeStr = DateFormat('HH:mm:ss').format(now);
      final empName = widget.auth.user?.name ?? 'Karyawan';
      final typeLabel = widget.type == 'check_in' ? 'Absen Masuk' : 'Absen Pulang';
      final locLabel = _isHomecare ? 'Homecare' : (_isOutside ? 'Di luar radius' : 'Kantor Lelap');

      final lines = [
        'Lelap Mom Baby Care',
        'Nama: $empName',
        'Status: $typeLabel',
        'Hari/Tanggal: $dateStr',
        'Jam: $timeStr WIB',
        'GPS: ON',
        'Alamat: $_address',
        'Lat: $_latitude',
        'Long: $_longitude',
        'Lokasi: $locLabel',
      ];

      // Draw watermark 
      final text = [
        'Lelap Mom Baby Care',
        'Nama: $empName — $typeLabel',
        '$dateStr — $timeStr WIB',
        'GPS: ON — $_address',
        'Lat: $_latitude / Long: $_longitude',
        'Lokasi: $locLabel',
      ].join('\n');
      img.drawString(image, text, font: img.arial14, x: 10, y: image.height - 100, color: img.ColorRgba8(255, 255, 255, 200));
      img.drawString(image, text, font: img.arial14, x: 11, y: image.height - 99, color: img.ColorRgba8(0, 0, 0, 100));

      final dir = await getTemporaryDirectory();
      final watermarkedPath = '${dir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _photoFile!.copy(watermarkedPath);
      _watermarkedPhotoPath = watermarkedPath;
    } catch (e) {
      _watermarkedPhotoPath = _photoFile!.path;
    }
  }

  Future<void> _submit() async {
    if (_isOutside && !_isHomecare) {
      setState(() => _error = 'Anda di luar radius kantor. Pilih Homecare atau batalkan.');
      return;
    }
    if (_photoFile == null) {
      setState(() => _error = 'Foto selfie wajib diambil.');
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm:ss').format(now);

      final fields = <String, String>{
        'attendanceDate': dateStr,
        'deviceTime': now.toIso8601String(),
        'latitude': _latitude.toString(),
        'longitude': _longitude.toString(),
        'gpsAddress': _address,
        'gpsStatus': 'ON',
        'isMockLocation': _isMock.toString(),
        'deviceId': _deviceId ?? 'unknown',
        'locationType': _isHomecare ? 'homecare' : (_isOutside ? 'outside_radius' : 'office'),
      };

      if (_isHomecare) {
        fields['homecareAddress'] = _homecareAddrCtrl.text;
        fields['homecareNote'] = _homecareNoteCtrl.text;
      }

      final photoPath = _watermarkedPhotoPath ?? _photoFile!.path;
      final res = await widget.api.postMultipart(
        widget.type == 'check_in' ? ApiConfig.checkIn : ApiConfig.checkOut,
        fields: fields,
        files: [File(photoPath)],
        fileField: 'selfie',
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Absen berhasil!'), backgroundColor: AppTheme.successColor),
          );
          Navigator.pop(context);
        }
      } else {
        final data = jsonDecode(res.body);
        setState(() => _error = data['message'] ?? 'Gagal mengirim absensi.');
      }
    } catch (e) {
      setState(() => _error = 'Gagal terhubung ke server. Coba lagi.');
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'check_in' ? 'Absen Masuk' : 'Absen Pulang';
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_gpsChecking)
              const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mengecek GPS...', style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ))
            else ...[
              _buildStatusCard(),
              const SizedBox(height: 16),
              if (_isOutside && !_isHomecare) _buildHomecareOption(),
              if (_isHomecare) _buildHomecareForm(),
              const SizedBox(height: 16),
              if (!_photoTaken)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _gpsReady ? _takePhoto : null,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto Selfie'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                )
              else ...[
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    image: _photoFile != null ? DecorationImage(image: FileImage(_photoFile!), fit: BoxFit.contain) : null,
                  ),
                  child: _photoFile == null
                      ? const Center(child: Text('Foto tidak tersedia', style: TextStyle(color: Colors.white54)))
                      : null,
                ),
                const SizedBox(height: 8),
                const Text('✓ Foto selfie diambil', style: TextStyle(color: AppTheme.successColor)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.dangerColor)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _photoTaken && !_submitting ? _submit : null,
                  icon: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Mengirim...' : 'Kirim Absensi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = _isMock
        ? AppTheme.dangerColor
        : _isOutside
            ? AppTheme.warningColor
            : AppTheme.successColor;
    final icon = _isMock
        ? Icons.warning
        : _isOutside
            ? Icons.location_off
            : Icons.location_on;
    final status = _isMock
        ? 'Terdeteksi Fake GPS!'
        : _isOutside
            ? 'Di luar radius kantor (${_distance?.toStringAsFixed(0)}m)'
            : 'Dalam radius kantor (${_distance?.toStringAsFixed(0)}m)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 8),
          Text(_address, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text('${_latitude?.toStringAsFixed(6)}, ${_longitude?.toStringAsFixed(6)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (_isMock) const Text('⚠️ Lokasi terindikasi palsu. Absensi akan ditandai review.',
              style: TextStyle(color: AppTheme.dangerColor, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHomecareOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('Anda di luar radius kantor.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isHomecare = true),
              icon: const Icon(Icons.home_work),
              label: const Text('Saya Sedang Homecare'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.infoColor,
                side: const BorderSide(color: AppTheme.infoColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomecareForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.check_circle, color: AppTheme.infoColor, size: 20),
            SizedBox(width: 8),
            Text('Mode Homecare Aktif', style: TextStyle(color: AppTheme.infoColor, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _homecareAddrCtrl,
            decoration: const InputDecoration(labelText: 'Alamat Homecare *', hintText: 'Jl. contoh no. 123'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _homecareNoteCtrl,
            decoration: const InputDecoration(labelText: 'Catatan Tugas', hintText: 'Contoh: Perawatan bayi, Nama klien...'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isHomecare = false),
            child: const Text('Batal Homecare', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ HISTORY SCREEN ═══════════════════════

class HistoryScreen extends StatefulWidget {
  final ApiService api;
  const HistoryScreen({super.key, required this.api});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AttendanceSummary> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.get(ApiConfig.history);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _history = data.map((e) => AttendanceSummary.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Riwayat Absensi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text('Belum ada riwayat absensi.', style: TextStyle(color: Colors.white60)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _history[i];
                      final color = item.hasCheckIn && item.hasCheckOut
                          ? AppTheme.successColor
                          : item.dailyStatus == 'telat'
                              ? AppTheme.warningColor
                              : AppTheme.dangerColor;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.cardDecoration,
                        child: Row(
                          children: [
                            Container(width: 4, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.attendanceDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(item.statusLabel, style: TextStyle(color: color, fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (item.checkInTime != null) Text('${item.checkInTime}', style: const TextStyle(fontSize: 13)),
                                if (item.checkOutTime != null) Text('${item.checkOutTime}', style: const TextStyle(fontSize: 13, color: Colors.white60)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ═══════════════════════ SCHEDULE SCREEN ═══════════════════════

class ScheduleScreen extends StatefulWidget {
  final ApiService api;
  const ScheduleScreen({super.key, required this.api});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.get(ApiConfig.schedule);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _schedules = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Jadwal Saya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? const Center(child: Text('Belum ada jadwal.', style: TextStyle(color: Colors.white60)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedules.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final s = _schedules[i];
                      final isWork = s['scheduleStatus'] != 'libur_shift';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.cardDecoration,
                        child: Row(
                          children: [
                            Icon(isWork ? Icons.work : Icons.beach_access, color: isWork ? AppTheme.successColor : Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['workDate'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(isWork ? 'Masuk' : 'Libur', style: TextStyle(color: isWork ? AppTheme.successColor : Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
