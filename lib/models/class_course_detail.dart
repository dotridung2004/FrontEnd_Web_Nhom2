
import 'dart:convert'; // <-- SỬA LỖI: Thêm 'dart:'
import 'class_course.dart';
import '../table/user.dart';
import 'schedule.dart';

ClassCourseDetail classCourseDetailFromJson(String str) => ClassCourseDetail.fromJson(json.decode(str));

class ClassCourseDetail {
final ClassCourse classCourse; // Thông tin cơ bản
final List<User> students;
final List<Schedule> schedules;

ClassCourseDetail({
required this.classCourse,
required this.students,
required this.schedules,
});

factory ClassCourseDetail.fromJson(Map<String, dynamic> json) {
// Giả định API trả về cấu trúc:
// {
//   "class_course": { ... (thông tin ClassCourse) ... },
//   "students": [ ... (danh sách sinh viên) ... ],
//   "schedules": [ ... (danh sách lịch học) ... ]
// }

return ClassCourseDetail(
classCourse: ClassCourse.fromJson(json["class_course"] ?? json),

students: (json["students"] as List? ?? [])
    .map((x) => User.fromJson(x))
    .toList(),

schedules: (json["schedules"] as List? ?? [])
    .map((x) => Schedule.fromJson(x))
    .toList(),
);
}
}
