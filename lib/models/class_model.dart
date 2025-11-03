class ClassModel {
  final int id;
  final String name;
  // Bạn có thể thêm các trường khác nếu API trả về, ví dụ:
  // final String academicYear;
  // final int semester;

  ClassModel({
    required this.id,
    required this.name,
    // this.academicYear,
    // this.semester,
  });

  // Factory constructor để parse JSON
  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      // academicYear: json['academic_year'],
      // semester: json['semester'],
    );
  }
}