import 'dart:convert';

List<Department> departmentListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Department>.from(data.map((x) => Department.fromJson(x)));
}

class Department {
  final int id;
  final String code; // Mã khoa (CNTT)
  final String name; // Tên khoa (Công nghệ thông tin)

  // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
  // Thêm headId để khớp với database
  // Xóa description vì database không có
  final int? headId;
  // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

  final int teacherCount; // Số lượng giảng viên
  final int divisionCount; // Số lượng bộ môn

  Department({
    required this.id,
    required this.code,
    required this.name,
    this.headId,        // Cập nhật
    required this.teacherCount,
    required this.divisionCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',

      // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
      // Đọc head_id từ JSON (nếu có)
      headId: (json['head_id'] as num?)?.toInt(), // Sẽ là null nếu JSON không có
      // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
      divisionCount: (json['divisions_count'] as num?)?.toInt() ?? 0,
    );
  }
}