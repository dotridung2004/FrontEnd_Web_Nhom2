// lib/models/lecturer.dart

import 'package:intl/intl.dart'; // <<< THÊM IMPORT NÀY

class Lecturer {
  final int id;
  final String lecturerCode;
  final String fullName;
  final String email;
  final String? dob;
  final String? phoneNumber;
  final String departmentName;
  final int departmentId;

  // <<< SỬA LẠI CONSTRUCTOR CHO ĐÚNG CÚ PHÁP
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


  factory Lecturer.fromJson(Map<String, dynamic> json) {
    String formattedDob = json['dob'] ?? '';
    if (json['dob'] != null && json['dob'].isNotEmpty) {
      try {
        // API trả về 'YYYY-MM-DD', chuyển thành 'dd/MM/yyyy' để hiển thị
        final date = DateTime.parse(json['dob']);
        formattedDob = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        // Giữ nguyên nếu định dạng không đúng
        formattedDob = json['dob'];
      }
    }

    return Lecturer(
      id: json['id'] ?? 0,
      lecturerCode: json['user_code'] ?? '',
      fullName: json['name'] ?? 'Không có tên',
      email: json['email'] ?? '',
      dob: formattedDob,
      phoneNumber: json['phone_number'],
      departmentName: json['department']?['name'] ?? 'N/A',
      departmentId: json['department_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'email': email,
      'user_code': lecturerCode,
      'department_id': departmentId,
      'phone_number': phoneNumber,
      'dob': dob,
    };
  }
}