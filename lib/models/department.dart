// file: lib/models/department.dart

class Department {
  final int id;
  final String name;
  final String? description; // Mô tả có thể là null

  Department({
    required this.id,
    required this.name,
    this.description,
  });

  // Factory constructor để chuyển đổi JSON từ API thành đối tượng Department
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A', // Tên khoa
      description: json['description'],
    );
  }
}