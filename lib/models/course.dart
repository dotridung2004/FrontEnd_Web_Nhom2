import 'dart:convert';

List<Course> courseListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Course>.from(data.map((x) => Course.fromJson(x)));
}

class Course {
  final int id;
  final String code; // Mã học phần (CSE360)
  final String name; // Tên học phần (Android)
  final int credits; // Số tín chỉ (3)
  final String departmentName; // Khoa phụ trách
  final String type; // Loại học phần (Bắt buộc)

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.departmentName,
    required this.type,
  });

  factory Course.fromJson(Map<String, dynamic> json) {

    // ✅ SỬA LỖI TẠI ĐÂY:
    // Thêm logic để đọc cả 2 kiểu dữ liệu (phẳng và lồng nhau)
    final String deptName = json['departmentName'] // Đọc kiểu phẳng (vd: "Khoa CNTT")
        ?? json['department']?['name'] // Đọc kiểu lồng nhau (vd: { "name": "Khoa CNTT" })
        ?? 'N/A';

    return Course(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      departmentName: deptName, // Gán tên khoa đã tìm được
      type: json['subject_type'] ?? 'N/A',
    );
  }
}