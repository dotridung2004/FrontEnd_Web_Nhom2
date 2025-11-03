// Import các model của bạn
import '../table/user.dart';
import 'course.dart';
import 'department.dart';
import 'division.dart';
import 'room.dart'; // ✅ THÊM IMPORT NÀY

class ClassCourseFormData {
  final List<User> teachers;
  final List<Course> courses;
  final List<Department> departments;
  final List<Division> divisions;
  final List<String> semesters;
  final List<Room> rooms; // ✅ THÊM TRƯỜNG NÀY

  ClassCourseFormData({
    required this.teachers,
    required this.courses,
    required this.departments,
    required this.divisions,
    required this.semesters,
    required this.rooms, // ✅ THÊM VÀO CONSTRUCTOR
  });

  factory ClassCourseFormData.fromJson(Map<String, dynamic> json) {
    return ClassCourseFormData(
      teachers: (json['teachers'] as List? ?? [])
          .map((i) => User.fromJson(i))
          .toList(),

      courses: (json['courses'] as List? ?? [])
          .map((i) => Course.fromJson(i))
          .toList(),

      departments: (json['departments'] as List? ?? [])
          .map((i) => Department.fromJson(i))
          .toList(),

      divisions: (json['divisions'] as List? ?? [])
          .map((i) => Division.fromJson(i))
          .toList(),

      semesters: List<String>.from(json['semesters'] ?? []),

      // ✅ THÊM LOGIC PARSE CHO ROOMS
      rooms: (json['rooms'] as List? ?? [])
          .map((i) => Room.fromJson(i))
          .toList(),
    );
  }
}