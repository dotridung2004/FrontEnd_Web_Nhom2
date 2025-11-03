// file: lib/models/class_course_assignment.dart

class ClassCourseAssignment {
  final int id;
  final String displayName;

  ClassCourseAssignment({required this.id, required this.displayName});

  factory ClassCourseAssignment.fromJson(Map<String, dynamic> json) {
    // --- BẮT ĐẦU SỬA LỖI (FIX LỖI N/A) ---
    // Backend (ClassCourseAssignmentController@index)
    // không còn trả về 'display_name'.
    // Nó trả về một object phức tạp. Chúng ta cần tự xây dựng display_name.

    // 1. Lấy tên giáo viên (Safely)
    final String teacherName = (json['teacher'] is Map && json['teacher']['name'] != null)
        ? json['teacher']['name']
        : 'N/A';

    // 2. Lấy tên môn học (Safely)
    final String courseName = (json['course'] is Map && json['course']['name'] != null)
        ? json['course']['name']
        : 'N/A';

    // 3. Lấy tên lớp học phần (backend gửi key là 'name' cho tên lớp)
    final String className = json['name'] ?? 'N/A';

    // 4. Xây dựng lại display_name
    final String builtDisplayName = "GV: $teacherName | Môn: $courseName | Lớp: $className";

    return ClassCourseAssignment(
      id: json['id'],
      // 5. Sử dụng displayName đã xây dựng.
      //    (Dùng giá trị 'display_name' cũ nếu có, nếu không thì dùng giá trị mới xây dựng)
      displayName: json['display_name'] ?? builtDisplayName,
    );
    // --- KẾT THÚC SỬA LỖI ---
  }
}