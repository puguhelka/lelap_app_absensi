class ApiConfig {
  // Ganti sesuai environment
  // Emulator Android: http://10.0.2.2:3000
  // HP fisik: http://IP_KOMPUTER:3000
  // Production: https://lelap.web.id
  static const String defaultBaseUrl = 'https://lelap.web.id';

  static const Duration timeout = Duration(seconds: 30);

  // Endpoint Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Endpoint Mobile
  static const String home = '/api/mobile/home';
  static const String todayAttendance = '/api/mobile/today-attendance';
  static const String checkIn = '/api/mobile/attendance/check-in';
  static const String checkOut = '/api/mobile/attendance/check-out';
  static const String history = '/api/mobile/attendance/history';
  static const String schedule = '/api/mobile/schedule';
  static const String registerDevice = '/api/mobile/device/register';
}
