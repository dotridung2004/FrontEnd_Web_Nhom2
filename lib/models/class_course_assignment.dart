// file: lib/models/class_course_assignment.dart

class ClassCourseAssignment {
  final int id;
  final String displayName;

  ClassCourseAssignment({required this.id, required this.displayName});

  factory ClassCourseAssignment.fromJson(Map<String, dynamic> json) {
    return ClassCourseAssignment(
      id: json['id'],
      displayName: json['display_name'] ?? 'N/A',
    );
  }
}