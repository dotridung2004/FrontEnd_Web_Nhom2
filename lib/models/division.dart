// lib/models/division.dart
import 'dart:convert';

class Division {
  final int id;
  final String code; // Mã bộ môn
  final String name; // Tên bộ môn
  final String departmentName; // Khoa
  final int teacherCount; // Số lượng giảng viên
  final int courseCount; // Số lượng môn học

  Division({
    required this.id,
    required this.code,
    required this.name,
    required this.departmentName,
    required this.teacherCount,
    required this.courseCount,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',

      // Giả định 'khoa' là một quan hệ lồng nhau
      departmentName: json['department']?['name'] ?? 'N/A',

      // Giả định 'so_luong_giang_vien' được lấy từ withCount
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,

      // Giả định 'so_luong_mon_hoc' được lấy từ withCount
      courseCount: (json['courses_count'] as num?)?.toInt() ?? 0,
    );
  }
}