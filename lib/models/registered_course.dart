
import 'dart:convert';

class RegisteredCourse {
  final int id;
  final String classCode;     // Mã học phần (CSE360)
  final String courseName;    // Tên học phần
  final String teacherName;   // Giảng viên
  final String semester;      // Học kì
  final int totalStudents;    // Tổng số SV

  RegisteredCourse({
    required this.id,
    required this.classCode,
    required this.courseName,
    required this.teacherName,
    required this.semester,
    required this.totalStudents,
  });

  factory RegisteredCourse.fromJson(Map<String, dynamic> json) {
    return RegisteredCourse(
      id: json['id'] ?? 0,
      // 'name' là mã lớp (CSE360) từ ClassCourseAssignment
      classCode: json['name'] ?? 'N/A',

      // Lấy tên học phần từ quan hệ
      courseName: json['course']?['name'] ?? 'N/A',

      // Lấy tên giảng viên từ quan hệ
      teacherName: json['teacher']?['name'] ?? 'N/A',
      semester: json['semester'] ?? 'N/A',

      // Lấy số lượng từ 'withCount' (Laravel tự động thêm '_count')
      totalStudents: (json['students_count'] as num?)?.toInt() ?? 0,
    );
  }
}