import 'dart:convert';
import 'class_course.dart';
import 'schedule.dart';

ClassCourseDetail classCourseDetailFromJson(String str) => ClassCourseDetail.fromJson(json.decode(str));

// ✅ SỬA LỖI: Thêm class 'Student' mà màn hình đang yêu cầu
class Student {
  final int id;
  final String name;
  final String email;
  final String firstName;
  final String lastName;
  final String status;
  final String role;
  final String phoneNumber;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.role,
    required this.phoneNumber,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      status: json['status'] ?? 'inactive',
      role: json['role'] ?? 'student',
      phoneNumber: json['phone_number'] ?? 'N/A',
    );
  }
}


class ClassCourseDetail {
  final ClassCourse classCourse; // Thông tin cơ bản
  final List<Student> students; // <-- Sử dụng Student
  final List<Schedule> schedules;

  ClassCourseDetail({
    required this.classCourse,
    required this.students,
    required this.schedules,
  });

  factory ClassCourseDetail.fromJson(Map<String, dynamic> json) {
    return ClassCourseDetail(
      classCourse: ClassCourse.fromJson(json["class_course"] ?? json),

      students: (json["students"] as List? ?? [])
          .map((x) => Student.fromJson(x)) // <-- Sử dụng Student
          .toList(),

      schedules: (json["schedules"] as List? ?? [])
          .map((x) => Schedule.fromJson(x))
          .toList(),
    );
  }
}

