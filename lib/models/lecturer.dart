// lib/models/lecturer.dart

class Lecturer {
  final int id;
  final String lecturerCode;
  final String fullName;
  final String email;
  final String? dob;
  final String? phoneNumber;
  final String departmentName;
  final int departmentId;

  Lecturer({
    required this.id,
    required this.lecturerCode,
    required this.fullName,
    required this.email,
    this.dob,
    this.phoneNumber,
    required this.departmentName,
    required this.departmentId,
  });

  // Chuyển đổi từ JSON (nhận từ API) sang Object Lecturer
  factory Lecturer.fromJson(Map<String, dynamic> json) {
    return Lecturer(
      id: json['id'] ?? 0,
      lecturerCode: json['user_code'] ?? '', // SỬA LẠI: API trả về 'user_code'
      fullName: json['name'] ?? 'Không có tên',
      email: json['email'] ?? '',
      dob: json['dob'], // SỬA LẠI: API trả về 'dob'
      phoneNumber: json['phone_number'],
      // Giữ nguyên logic xử lý an toàn cho object lồng nhau
      departmentName: json['department']?['name'] ?? 'N/A',
      // Lấy trực tiếp department_id từ cấp cao nhất
      departmentId: json['department_id'] ?? 0, // SỬA LẠI: Lấy 'department_id'
    );
  }

  // >>> BỔ SUNG: Chuyển đổi từ Object Lecturer sang JSON (để gửi lên API)
  Map<String, dynamic> toJson() {
    return {
      'user_code': lecturerCode,
      'name': fullName,
      'email': email,
      'dob': dob,
      'phone_number': phoneNumber,
      'department_id': departmentId,
      // Lưu ý: Mật khẩu sẽ cần được thêm riêng vào map này khi tạo mới giảng viên.
      // Ví dụ: final data = lecturer.toJson(); data['password'] = '123456';
    };
  }
}