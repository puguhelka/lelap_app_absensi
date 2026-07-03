class AttendanceSummary {
  final int? id;
  final int employeeId;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String dailyStatus;
  final bool isLate;
  final bool isHomecare;
  final bool isIncomplete;
  final bool needsReview;
  final String? adminNote;
  final String? employeeName;
  final String? employeePosition;

  AttendanceSummary({
    this.id,
    required this.employeeId,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.dailyStatus = 'belum_absen',
    this.isLate = false,
    this.isHomecare = false,
    this.isIncomplete = false,
    this.needsReview = false,
    this.adminNote,
    this.employeeName,
    this.employeePosition,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      id: json['id'],
      employeeId: json['employeeId'] ?? 0,
      attendanceDate: json['attendanceDate'] ?? '',
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      dailyStatus: json['dailyStatus'] ?? 'belum_absen',
      isLate: json['isLate'] ?? false,
      isHomecare: json['isHomecare'] ?? false,
      isIncomplete: json['isIncomplete'] ?? false,
      needsReview: json['needsReview'] ?? false,
      adminNote: json['adminNote'],
      employeeName: json['employeeName'],
      employeePosition: json['employeePosition'],
    );
  }

  String get statusLabel {
    switch (dailyStatus) {
      case 'hadir_lengkap': return 'Hadir Lengkap';
      case 'belum_absen': return 'Belum Absen';
      case 'hanya_masuk': return 'Hanya Masuk';
      case 'hanya_pulang': return 'Hanya Pulang';
      case 'telat': return 'Telat';
      case 'izin': return 'Izin';
      case 'sakit': return 'Sakit';
      case 'cuti': return 'Cuti';
      case 'absensi_tidak_lengkap': return 'Tidak Lengkap';
      case 'libur_shift': return 'Libur Shift';
      default: return dailyStatus;
    }
  }

  bool get hasCheckIn => checkInTime != null;
  bool get hasCheckOut => checkOutTime != null;
}

class Shift {
  final int id;
  final String name;
  final String start;
  final String end;
  final int tolerance;
  final String days;
  final bool active;

  Shift({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    this.tolerance = 15,
    this.days = 'Senin-Sabtu',
    this.active = true,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      tolerance: json['tolerance'] ?? 15,
      days: json['days'] ?? '',
      active: json['active'] ?? true,
    );
  }
}

class AttendanceRecord {
  final int id;
  final int employeeId;
  final String attendanceDate;
  final String attendanceType;
  final String serverTime;
  final String attendanceTime;
  final double? latitude;
  final double? longitude;
  final String? locationType;
  final bool isMockLocation;
  final String? photoPath;
  final String? homecareNote;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.attendanceDate,
    required this.attendanceType,
    required this.serverTime,
    required this.attendanceTime,
    this.latitude,
    this.longitude,
    this.locationType,
    this.isMockLocation = false,
    this.photoPath,
    this.homecareNote,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      attendanceDate: json['attendanceDate'] ?? '',
      attendanceType: json['attendanceType'] ?? '',
      serverTime: json['serverTime'] ?? '',
      attendanceTime: json['attendanceTime'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationType: json['locationType'],
      isMockLocation: json['isMockLocation'] ?? false,
      photoPath: json['photoPath'],
      homecareNote: json['homecareNote'],
    );
  }

  bool get isCheckIn => attendanceType == 'check_in';
  bool get isCheckOut => attendanceType == 'check_out';
}
