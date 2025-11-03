import 'class_course.dart'; // Model 'phẳng' bạn cung cấp
import 'schedule.dart';     // Model 'phẳng' bạn cung cấp

// Model cho Sinh viên (Dựa trên Controller)
class Student {
  final int id;
  final String name;
  final String email;
  // ... (Thêm các trường khác nếu cần)

  Student({required this.id, required this.name, required this.email});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
    );
  }
}

// Model chính cho màn hình chi tiết
class RegisteredCourseDetail {
  final ClassCourse classCourse;
  final List<Student> students;
  final List<Schedule> schedules;

  RegisteredCourseDetail({
    required this.classCourse,
    required this.students,
    required this.schedules,
  });

  factory RegisteredCourseDetail.fromJson(Map<String, dynamic> json) {
    final classCourseData = json['class_course'];
    final List<dynamic> studentsData = json['students'] ?? [];
    final List<dynamic> schedulesData = json['schedules'] ?? [];

    return RegisteredCourseDetail(
      // Chỗ này sẽ gọi `ClassCourse.fromJson` (phẳng) của bạn
      classCourse: classCourseData != null
          ? ClassCourse.fromJson(classCourseData)
          : ClassCourse.empty(), // ✅ Dùng hàm empty() bạn đã thêm

      students: studentsData.map((item) => Student.fromJson(item)).toList(),

      // Chỗ này sẽ gọi `Schedule.fromJson` (phẳng) của bạn
      schedules: schedulesData.map((item) => Schedule.fromJson(item)).toList(),
    );
  }
}