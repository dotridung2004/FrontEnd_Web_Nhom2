import 'dart:convert';

// Hàm helper để decode json, trả về một Map
Map<String, dynamic> userJsonToMap(String str) =>
    json.decode(str) as Map<String, dynamic>;

// Hàm helper để encode, biến object User thành chuỗi JSON
String userToJson(User data) => json.encode(data.toJson());

class User {
  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String status;
  final String? avatarUrl;
  final String? gender;
  final String? dateOfBirth; // Giữ ở dạng String (YYYY-MM-DD)

  User({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
  });

  /// Factory constructor: Tạo một thực thể User từ JSON (Map)
  ///
  /// API trả về các trường theo dạng snake_case (ví dụ: 'first_name'),
  /// chúng ta cần map chúng sang các biến camelCase (ví dụ: firstName).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      avatarUrl: json['avatar_url'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
    );
  }

  /// Method: Chuyển đổi thực thể User thành một Map (JSON)
  ///
  /// Dùng khi bạn muốn gửi dữ liệu (ví dụ: tạo user, cập nhật user)
  /// lên API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'status': status,
      'avatar_url': avatarUrl,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      // Lưu ý: Không bao gồm 'password' ở đây.
      // Việc xử lý password nên được thực hiện riêng biệt.
    };
  }

  // (Tùy chọn) Hàm copyWith để dễ dàng tạo bản sao và chỉnh sửa
  User copyWith({
    int? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? role,
    String? status,
    String? avatarUrl,
    String? gender,
    String? dateOfBirth,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
}