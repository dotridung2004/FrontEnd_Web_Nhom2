import 'dart:convert';

// Helper
List<Schedule> scheduleListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Schedule>.from(data.map((x) => Schedule.fromJson(x)));
}

class Schedule {
  final int id;
  final String teacherName;
  final String classCode; // Lớp học phần
  final String courseName; // Học phần
  final String semester; // Học kỳ
  final String roomName;

  Schedule({
    required this.id,
    required this.teacherName,
    required this.classCode,
    required this.courseName,
    required this.semester,
    required this.roomName,
  });

  /// Factory constructor để parse JSON từ API
  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? 0,

      // Lấy tên Giảng viên (lồng nhau)
      teacherName: json['class_course_assignment']?['teacher']?['name'] ?? 'N/A',

      // Lấy tên Lớp học phần (lồng nhau)
      classCode: json['class_course_assignment']?['class_model']?['name'] ?? 'N/A',

      // Lấy tên Học phần (lồng nhau)
      courseName: json['class_course_assignment']?['course']?['name'] ?? 'N/A',

      // Giả sử 'semester' (Học kỳ) là một trường trực tiếp
      // (Nếu nó cũng lồng, bạn cần sửa lại đường dẫn)
      semester: json['class_course_assignment']?['class_model']?['semester'] ?? 'Học kỳ N/A',

      // Lấy tên Phòng (lồng nhau)
      roomName: json['room']?['name'] ?? 'N/A',
    );
  }
}