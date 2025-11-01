import 'dart:convert';

List<ClassCourse> classCourseListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<ClassCourse>.from(data.map((x) => ClassCourse.fromJson(x)));
}

class ClassCourse {
  final int id;
  final String name; // Tên lớp học phần (CSE360)
  final String teacherName; // Giảng viên
  final String departmentName; // Khoa
  final String courseName; // Tên học phần
  final String semester; // Học kỳ
  final String divisionName; // <-- ✅ PHẢI CÓ TRƯỜNG NÀY

  ClassCourse({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.departmentName,
    required this.courseName,
    required this.semester,
    required this.divisionName, // <-- ✅ THÊM VÀO CONSTRUCTOR
  });

  /// Factory constructor để parse JSON
  factory ClassCourse.fromJson(Map<String, dynamic> json) {
    return ClassCourse(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',

      teacherName: json['teacher']?['name'] ?? 'N/A',
      departmentName: json['course']?['department']?['name'] ?? 'N/A',
      courseName: json['course']?['name'] ?? 'N/A',

      // ==========================================================
      // ✅ SỬA LỖI TẠI ĐÂY:
      // Đọc 'semester' và 'divisionName' đã được format bởi backend
      // ==========================================================
      semester: json['semester'] ?? 'N/A', // Đọc 'HK1 2024-2025'
      divisionName: json['division']?['name'] ?? 'N/A', // Đọc tên bộ môn
    );
  }
}