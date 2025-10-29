// file: lib/models/lecturer.dart

class Lecturer {
  final int id;
  final String lecturerCode;
  final String fullName;
  final String email;
  final String? dob; // Ngày sinh có thể null
  final String? phoneNumber; // SĐT có thể null
  final String departmentName;
  final int departmentId;

  Lecturer({
    required this.id,
    required this.lecturerCode,
    required this.fullName,
    required this.email,
    this.dob,
    this.phoneNumber,
    required this.departmentName,
    required this.departmentId,
  });

  factory Lecturer.fromJson(Map<String, dynamic> json) {
    return Lecturer(
      id: json['id'] ?? 0,
      // Dùng ?? '' để đảm bảo không bao giờ là null
      lecturerCode: json['lecturer_code'] ?? '',
      fullName: json['name'] ?? 'Không có tên', // Giả sử key là 'name'
      email: json['email'] ?? '',
      dob: json['date_of_birth'], // Giữ null nếu API không trả về
      phoneNumber: json['phone_number'], // Giữ null nếu API không trả về
      // Xử lý an toàn cho object lồng nhau
      departmentName: json['department']?['name'] ?? 'N/A',
      departmentId: json['department']?['id'] ?? 0,
    );
  }
}