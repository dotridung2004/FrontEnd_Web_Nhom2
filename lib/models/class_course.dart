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
  final String divisionName;
  final String roomName; // ✅ THÊM TRƯỜNG NÀY

  ClassCourse({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.departmentName,
    required this.courseName,
    required this.semester,
    required this.divisionName,
    required this.roomName, // ✅ THÊM VÀO CONSTRUCTOR
  });

  /// Factory constructor để parse JSON
  factory ClassCourse.fromJson(Map<String, dynamic> json) {
    return ClassCourse(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      teacherName: json['teacher']?['name'] ?? 'N/A',
      departmentName: json['course']?['department']?['name'] ?? 'N/A',
      courseName: json['course']?['name'] ?? 'N/A',
      semester: json['semester'] ?? 'N/A',
      divisionName: json['division']?['name'] ?? 'N/A',
      roomName: json['room']?['name'] ?? 'N/A', // ✅ THÊM LOGIC PARSE
    );
  }

  /// Factory constructor để tạo một đối tượng ClassCourse rỗng
  factory ClassCourse.empty() {
    return ClassCourse(
      id: 0,
      name: 'N/A',
      teacherName: 'N/A',
      departmentName: 'N/A',
      courseName: 'N/A',
      semester: 'N/A',
      divisionName: 'N/A',
      roomName: 'N/A', // ✅ THÊM VÀO HÀM EMPTY
    );
  }
}