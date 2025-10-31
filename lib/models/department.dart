// File: lib/models/department.dart
import 'dart:convert';

List<Department> departmentListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Department>.from(data.map((x) => Department.fromJson(x)));
}

class Department {
  final int id;
  final String code;
  final String name;
  final String? description; // (Dùng cho dialog Sửa/Xem)
  final int? headId;        // (Dùng cho dialog Sửa)

  // --- Các trường đã được map sẵn từ Backend ---
  // (Giống như template 'division.dart')
  final String headTeacherName; // Tên trưởng khoa
  final int teacherCount;     // Số lượng giảng viên
  final int majorsCount;      // Số lượng ngành (Thay vì divisionCount)

  Department({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.headId,
    // ---
    required this.headTeacherName,
    required this.teacherCount,
    required this.majorsCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    // (Phải khớp với JSON API trả về từ fetchPaginatedDepartments)
    return Department(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      description: json['description'],
      headId: (json['head_id'] as num?)?.toInt(),

      // --- Các trường map sẵn ---
      // (Backend phải trả về các key này)
      headTeacherName: json['head_teacher_name'] ?? 'N/A',
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
      majorsCount: (json['majors_count'] as num?)?.toInt() ?? 0,
    );
  }
}