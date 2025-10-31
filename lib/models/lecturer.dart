import 'package:intl/intl.dart';

class Lecturer {
  final int id;
  // <<< XÓA lecturerCode
  final String fullName;
  final String email;
  final String? dob;
  final String? phoneNumber;
  final String departmentName;
  final int departmentId;

  Lecturer({
    required this.id,
    // <<< XÓA lecturerCode
    required this.fullName,
    required this.email,
    this.dob,
    this.phoneNumber,
    required this.departmentName,
    required this.departmentId,
  });


  factory Lecturer.fromJson(Map<String, dynamic> json) {
    String? rawDob = json['date_of_birth'];
    String formattedDob = '';

    if (rawDob != null && rawDob.isNotEmpty) {
      try {
        final date = DateTime.parse(rawDob);
        formattedDob = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        formattedDob = rawDob;
      }
    }

    return Lecturer(
      id: json['id'] ?? 0,
      // <<< XÓA lecturerCode
      fullName: json['name'] ?? 'Không có tên',
      email: json['email'] ?? '',
      dob: formattedDob.isEmpty ? null : formattedDob,
      phoneNumber: json['phone_number'],
      departmentName: json['department']?['name'] ?? 'N/A',
      departmentId: json['department_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'email': email,
      // <<< XÓA user_code
      'department_id': departmentId,
      'phone_number': phoneNumber,
      'date_of_birth': dob,
    };
  }
}