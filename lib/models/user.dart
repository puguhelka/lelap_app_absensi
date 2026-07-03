class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? token;
  final int? employeeId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.token,
    this.employeeId,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      phone: json['phone'],
      token: token,
      employeeId: json['employee'] is Map ? json['employee']['id'] : json['employeeId'],
    );
  }

  bool get isAdmin => role == 'admin';
}

class HomeData {
  final String employeeName;
  final String employeePosition;
  final String? shiftName;
  final String? shiftStart;
  final String? shiftEnd;
  final String todayDate;
  final String? checkInTime;
  final String? checkOutTime;
  final String? dailyStatus;
  final bool hasCheckIn;
  final bool hasCheckOut;
  final bool isLate;
  final bool isHomecare;

  HomeData({
    required this.employeeName,
    required this.employeePosition,
    this.shiftName,
    this.shiftStart,
    this.shiftEnd,
    required this.todayDate,
    this.checkInTime,
    this.checkOutTime,
    this.dailyStatus,
    this.hasCheckIn = false,
    this.hasCheckOut = false,
    this.isLate = false,
    this.isHomecare = false,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final employee = json['employee'] as Map<String, dynamic>? ?? {};
    final shift = json['shift'] as Map<String, dynamic>?;
    return HomeData(
      employeeName: employee['fullName'] ?? employee['name'] ?? '',
      employeePosition: employee['position'] ?? '',
      shiftName: shift?['name'],
      shiftStart: shift?['start'],
      shiftEnd: shift?['end'],
      todayDate: today['attendanceDate'] ?? '',
      checkInTime: today['checkInTime'],
      checkOutTime: today['checkOutTime'],
      dailyStatus: today['dailyStatus'],
      hasCheckIn: today['checkInTime'] != null,
      hasCheckOut: today['checkOutTime'] != null,
      isLate: today['isLate'] ?? false,
      isHomecare: today['isHomecare'] ?? false,
    );
  }
}
