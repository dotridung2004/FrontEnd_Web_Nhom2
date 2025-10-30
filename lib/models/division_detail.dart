import 'dart:convert';
import 'division.dart'; // Import model Division gốc
import 'course.dart';   // Import Course (vẫn cần cho _buildCourseTable nếu giữ lại)
import '../table/user.dart';      // Import User để xem chi tiết

DivisionDetail divisionDetailFromJson(String str) => DivisionDetail.fromJson(json.decode(str));

class DivisionDetail extends Division {
  final List<User> teachersList;
  // final List<Course> coursesList; // <-- Xóa
  final String? description;

  DivisionDetail({
    required super.id,
    required super.code,
    required super.name,
    required super.departmentName,
    required super.teacherCount,
    // required super.courseCount, // <-- Xóa
    required this.teachersList,
    // required this.coursesList, // <-- Xóa
    this.description,
  }) : super(courseCount: 0); // <-- Truyền giá trị 0 mặc định cho courseCount của lớp cha

  factory DivisionDetail.fromJson(Map<String, dynamic> json) {
    return DivisionDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',
      departmentName: json['department']?['name'] ?? 'N/A',
      // Lấy teacherCount từ key 'teacherCount' (đã map ở controller) hoặc 'teachers_count'
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? (json['teachers_count'] as num?)?.toInt() ?? (json['teachers'] as List?)?.length ?? 0,
      // courseCount: 0, // <-- Xóa (đã xử lý ở super() )
      teachersList: json['teachersList'] != null && json['teachersList'] is List // Khớp key 'teachersList' từ controller
          ? List<User>.from(json['teachersList'].map((x) => User.fromJson(x)))
          : [],
      // coursesList: [], // <-- Xóa
      description: json['description'] as String?,
    );
  }
}