// lib/models/app_user.dart

import 'package:intl/intl.dart'; // Import để format ngày tháng

class AppUser {
  final int id;
  final String username; // Sẽ map từ trường 'name' của API
  final String email;    // Thêm trường email
  final String role;
  final String creationDate;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.creationDate,
  });

  // 👇 THÊM HÀM NÀY VÀO
  // Factory constructor để tạo AppUser từ JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Format lại ngày tháng từ API (vd: "2025-10-30T10:00:00.000000Z")
    DateTime parsedDate = DateTime.parse(json['created_at']);
    String formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

    return AppUser(
      id: json['id'],
      username: json['name'], // Map 'name' từ API vào 'username'
      email: json['email'],
      role: _formatRole(json['role']), // Gọi hàm để dịch vai trò
      creationDate: formattedDate,
    );
  }

  // Hàm helper để chuyển đổi role từ API sang tiếng Việt
  static String _formatRole(String apiRole) {
    switch (apiRole) {
      case 'student':
        return 'Sinh viên';
      case 'teacher':
        return 'Giảng viên';
      case 'training_office':
        return 'Phòng đào tạo';
      case 'head_of_department':
        return 'Trưởng bộ môn';
      default:
        return apiRole;
    }
  }
}