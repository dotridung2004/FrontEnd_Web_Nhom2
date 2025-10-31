// Tên file: lib/models/major.dart

import 'dart:convert';

class Major {
  final int id;
  final String code;
  final String name;
  final String departmentName;
  final int teacherCount;
  final DateTime updatedAt; // 👈 Đảm bảo bạn có dòng này

  Major({
    required this.id,
    required this.code,
    required this.name,
    required this.departmentName,
    required this.teacherCount,
    required this.updatedAt, // 👈 Và dòng này
  });

  factory Major.fromJson(Map<String, dynamic> json) {
    return Major(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      departmentName: json['departmentName'] ?? 'N/A',
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,

      // 👈 Và đảm bảo bạn parse 'updated_at'
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime(1970),
    );
  }
}