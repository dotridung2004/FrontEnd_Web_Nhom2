// lib/models/major.dart
import 'dart:convert';

class Major {
  final int id;
  final String code; // Mã ngành (TLA117)
  final String name; // Tên ngành (Kỹ thuật phần mềm)
  final String departmentName; // Khoa (Công nghệ thông tin)
  final int teacherCount; // Số lượng giảng viên

  Major({
    required this.id,
    required this.code,
    required this.name,
    required this.departmentName,
    required this.teacherCount,
  });

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',

      // Giả định 'khoa' là một quan hệ lồng nhau
      departmentName: json['department']?['name'] ?? 'N/A',

      // Giả định 'so_luong_giang_vien' được lấy từ withCount
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
    );
  }
}