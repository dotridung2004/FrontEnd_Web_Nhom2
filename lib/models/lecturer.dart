// file: lib/models/lecturer.dart

import 'package:intl/intl.dart';

class Lecturer {
  final int id;
  final String fullName;
  final String email;
  final String? dob; // Ngày sinh (đã định dạng dd/MM/yyyy)
  final String? phoneNumber;
  final String departmentName; // Tên khoa
  final int departmentId;     // ID khoa

  Lecturer({
    required this.id,
    required this.fullName,
    required this.email,
    this.dob,
    this.phoneNumber,
    required this.departmentName,
    required this.departmentId,
  });


  factory Lecturer.fromJson(Map<String, dynamic> json) {
    String? rawDob = json['date_of_birth'];
    String formattedDob = '';

    // --- 👇 FIX LỖI NGÀY SINH ---
    // API (Laravel) trả về 'YYYY-MM-DD' (ví dụ: '1990-05-20')
    if (rawDob != null && rawDob.isNotEmpty) {
      try {
        // DateTime.parse có thể đọc định dạng 'YYYY-MM-DD'
        final date = DateTime.parse(rawDob);
        // Chuyển đổi sang 'dd/MM/yyyy' để hiển thị
        formattedDob = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        // Nếu định dạng sai, giữ nguyên (hoặc trả về 'N/A')
        formattedDob = 'N/A';
      }
    }
    // --- Hết fix ngày sinh ---


    // --- 👇 FIX LỖI KHOA (ĐỌC ID) ---
    // Đảm bảo departmentId được đọc chính xác dù là int, String hay null
    int parsedDepartmentId;
    if (json['department_id'] is int) {
      parsedDepartmentId = json['department_id'];
    } else if (json['department_id'] is String) {
      parsedDepartmentId = int.tryParse(json['department_id']) ?? 0;
    } else {
      parsedDepartmentId = 0; // Mặc định là 0 nếu null
    }
    // --- Hết fix khoa (đọc ID) ---

    return Lecturer(
      id: json['id'] ?? 0,
      fullName: json['name'] ?? 'Không có tên',
      email: json['email'] ?? '',
      dob: formattedDob.isEmpty ? null : formattedDob, // Dùng ngày đã định dạng
      phoneNumber: json['phone_number'],

      // --- 👇 FIX LỖI KHOA (ĐỌC TÊN) ---
      // Đọc tên từ đối tượng 'department' lồng nhau
      // LecturerController của bạn có ->with('department') nên JSON sẽ có dạng:
      // { ..., "department": { "id": 1, "name": "Khoa CNTT" } }
      departmentName: json['department']?['name'] ?? 'N/A',
      departmentId: parsedDepartmentId, // Dùng ID đã được parse an toàn
    );
  }

  // Gửi dữ liệu lên server (cho Thêm/Sửa)
  Map<String, dynamic> toJson() {
    // Backend (LecturerController) của bạn mong đợi 'd/m/Y'
    return {
      'name': fullName,
      'email': email,
      'department_id': departmentId,
      'phone_number': phoneNumber,
      'date_of_birth': dob, // Gửi định dạng 'dd/MM/yyyy'
    };
  }
}