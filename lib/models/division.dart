import 'dart:convert';

List<Division> divisionListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Division>.from(data.map((x) => Division.fromJson(x)));
}

class Division {
  final int id;
  final String code; // Mã bộ môn
  final String name; // Tên bộ môn
  final String departmentName; // Khoa
  final int teacherCount; // Số lượng giảng viên
  final int courseCount; // Số lượng môn học
  final DateTime? updatedAt; // Thêm trường này để sắp xếp (tùy chọn)

  Division({
    required this.id,
    required this.code,
    required this.name,
    required this.departmentName,
    required this.teacherCount,
    required this.courseCount,
    this.updatedAt,
  });

  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',

      // 👇 SỬA LẠI CÁC DÒNG SAU ĐỂ KHỚP VỚI KEY CỦA CONTROLLER 👇

      // Đọc trực tiếp 'departmentName' (vì backend đã map sẵn)
      departmentName: json['departmentName'] ?? 'N/A',

      // Đọc 'teacherCount' (vì backend đã map sẵn)
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,

      // Đọc 'courseCount' (vì backend đã map sẵn)
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,

      // 👆 KẾT THÚC SỬA ĐỔI 👆

      // Parse updatedAt (dùng cho sắp xếp phía client nếu backend chưa sắp xếp)
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}