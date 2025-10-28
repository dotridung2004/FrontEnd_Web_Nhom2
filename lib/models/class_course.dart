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

  ClassCourse({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.departmentName,
    required this.courseName,
    required this.semester,
  });

  /// Factory constructor để parse JSON
  /// Giả định cấu trúc JSON lồng nhau từ API
  factory ClassCourse.fromJson(Map<String, dynamic> json) {
    return ClassCourse(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A', // Tên lớp (CSE360)

      // Giả định giảng viên được gán trực tiếp cho lớp này
      teacherName: json['teacher']?['name'] ?? 'N/A',

      // Giả định khoa từ môn học
      departmentName: json['course']?['department']?['name'] ?? 'N/A',

      // Giả định tên học phần
      courseName: json['course']?['name'] ?? 'N/A',

      // Giả định học kỳ
      semester: json['semester'] ?? 'N/A',
    );
  }
}