import 'dart:convert';

List<Department> departmentListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Department>.from(data.map((x) => Department.fromJson(x)));
}

class Department {
  final int id;
  final String code; // Mã khoa (CNTT)
  final String name; // Tên khoa (Công nghệ thông tin)
  final int teacherCount; // Số lượng giảng viên
  final int divisionCount; // Số lượng bộ môn

  Department({
    required this.id,
    required this.code,
    required this.name,
    required this.teacherCount,
    required this.divisionCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A', // Giả định backend trả về 'code'
      name: json['name'] ?? 'N/A', // Giả định backend trả về 'name'
      // Giả định backend trả về 'teachers_count' và 'divisions_count'
      // (Thường được thêm bằng withCount() trong Laravel)
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
      divisionCount: (json['divisions_count'] as num?)?.toInt() ?? 0,
    );
  }
}