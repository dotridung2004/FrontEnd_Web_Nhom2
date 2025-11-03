import 'dart:convert';
import 'department.dart';
import '../table/user.dart'; // (Đường dẫn đến model User của bạn)
import 'major.dart';
import 'division.dart';

DepartmentDetail departmentDetailFromJson(String str) => DepartmentDetail.fromJson(json.decode(str));

class DepartmentDetail {
  final Department department;
  final List<User> teachers;
  final List<Major> majors;
  final List<Division> divisions;

  DepartmentDetail({
    required this.department,
    required this.teachers,
    required this.majors,
    required this.divisions,
  });

  factory DepartmentDetail.fromJson(Map<String, dynamic> json) {
    // Cấu trúc này giả định API trả về một JSON lồng nhau
    // {
    //   "department": { ... (thông tin khoa) ... },
    //   "teachers": [ ... (danh sách giảng viên) ... ],
    //   "majors": [ ... (danh sách ngành) ... ],
    //   "divisions": [ ... (danh sách bộ môn) ... ]
    // }

    return DepartmentDetail(
      department: Department.fromJson(json["department"] ?? json),

      teachers: (json["teachers"] as List? ?? [])
          .map((x) => User.fromJson(x))
          .toList(),

      majors: (json["majors"] as List? ?? [])
          .map((x) => Major.fromJson(x))
          .toList(),

      divisions: (json["divisions"] as List? ?? [])
          .map((x) => Division.fromJson(x))
          .toList(),
    );
  }
}