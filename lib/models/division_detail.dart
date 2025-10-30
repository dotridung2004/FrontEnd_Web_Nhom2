import 'dart:convert';
import 'division.dart'; // Import model Division gốc
import 'course.dart';   // Import Course
import '../table/user.dart';      // Import User

DivisionDetail divisionDetailFromJson(String str) => DivisionDetail.fromJson(json.decode(str));

// Model Chi tiết Bộ môn
class DivisionDetail extends Division {
  final List<User> teachersList;
  final List<Course> coursesList;
  final String? description;

  DivisionDetail({
    required super.id,
    required super.code,
    required super.name,
    required super.departmentName, // Lấy từ lớp cha
    required super.teacherCount,   // Lấy từ lớp cha
    required super.courseCount,  // Lấy từ lớp cha
    required this.teachersList,
    required this.coursesList,
    this.description,
  }) : super(); // Gọi constructor của lớp cha Division

  factory DivisionDetail.fromJson(Map<String, dynamic> json) {
    // Cấu trúc này phải khớp với JSON trả về từ DivisionController@show
    return DivisionDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? 'N/A',
      name: json['name'] ?? 'N/A',

      // 👇 **** SỬA LỖI Ở ĐÂY **** 👇
      // Đọc trực tiếp 'departmentName' (String) mà backend gửi về
      departmentName: json['departmentName'] ?? 'N/A',

      // Đọc 'teacherCount' và 'courseCount' từ API chi tiết
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
      // 👆 **** KẾT THÚC SỬA LỖI **** 👆

      teachersList: json['teachersList'] != null && json['teachersList'] is List
          ? List<User>.from(json['teachersList'].map((x) => User.fromJson(x)))
          : [],
      coursesList: json['coursesList'] != null && json['coursesList'] is List
          ? List<Course>.from(json['coursesList'].map((x) => Course.fromJson(x)))
          : [],
      description: json['description'] as String?,
    );
  }
}