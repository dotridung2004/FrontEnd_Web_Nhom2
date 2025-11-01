// lib/models/course_detail.dart
import 'dart:convert';

CourseDetail courseDetailFromJson(String str) {
  return CourseDetail.fromJson(json.decode(str));
}

class CourseDetail {
  final int id;
  final String code;
  final String name;
  final int credits;
  final String description;
  final String subjectType; // "Bắt buộc", "Tùy chọn"

  // Thông tin khoa (ID và Tên)
  final int? departmentId;
  final String departmentName;

  CourseDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.description,
    required this.subjectType,
    this.departmentId,
    required this.departmentName,

  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    return CourseDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? '',
      subjectType: json['subject_type'] ?? 'N/A',

      // Giả định API trả về object lồng nhau
      departmentId: json['department']?['id'],
      departmentName: json['department']?['name'] ?? 'N/A',
    );
  }
}