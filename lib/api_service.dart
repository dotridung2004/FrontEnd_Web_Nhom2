// lib/table/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../table/home_summary.dart';
import '../table/user.dart';
import '../models/schedule.dart';
import '../models/lecturer.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }

  String? _token;

  Map<String, String> _getHeaders({bool needsAuth = true}) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void setToken(String? token) {
    _token = token;
  }

  Future<User> login(String email, String password) async {
    final Uri loginUrl = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        loginUrl,
        headers: _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);
        if (data['token'] != null) {
          setToken(data['token']);
        }
        return user;
      } else {
        _handleApiError(response, 'Đăng nhập thất bại');
      }
    } catch (e) {
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<PaginatedUsersResponse> fetchUsers(int page) async {
    final Uri url = Uri.parse('$baseUrl/users?page=$page');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return PaginatedUsersResponse.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi tải danh sách tài khoản');
      }
    } catch (e) {
      // Sửa lại khối catch để rõ ràng hơn
      throw Exception('Lỗi kết nối khi tải người dùng: ${e.toString()}');
    }
  }

  Future<AppUser> addUser(Map<String, dynamic> userData) async {
    final Uri url = Uri.parse('$baseUrl/users');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(userData),
      );
      if (response.statusCode == 201) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return AppUser.fromJson(responseData['data']);
      } else {
        _handleApiError(response, 'Thêm tài khoản thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi thêm người dùng: ${e.toString()}');
    }
  }

  Future<AppUser> updateUser(int id, Map<String, dynamic> userData) async {
    final Uri url = Uri.parse('$baseUrl/users/$id');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(userData),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return AppUser.fromJson(responseData['data']);
      } else {
        _handleApiError(response, 'Cập nhật tài khoản thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi cập nhật người dùng: ${e.toString()}');
    }
  }

  Future<void> deleteUser(int id) async {
    final Uri url = Uri.parse('$baseUrl/users/$id');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleApiError(response, 'Xóa tài khoản thất bại');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối khi xóa người dùng: ${e.toString()}');
    }
  }

  // --- CÁC HÀM API KHÁC ĐÃ SỬA LỖI ---
  Future<HomeSummary> fetchHomeSummary(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId/home-summary');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return HomeSummary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải dữ liệu trang chủ');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi tải trang chủ: ${e.toString()}');
    }
  }

  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(utf8.decode(response.bodyBytes));
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải lịch học');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi tải lịch học: ${e.toString()}');
    }
  }

  Future<List<Lecturer>> fetchLecturers() async {
    final Uri url = Uri.parse('$baseUrl/lecturers');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => Lecturer.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách giảng viên');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi tải giảng viên: ${e.toString()}');
    }
  }

  Future<Lecturer> addLecturer(Map<String, dynamic> lecturerData) async {
    final Uri url = Uri.parse('$baseUrl/lecturers');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(lecturerData),
      );
      if (response.statusCode == 201) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        return Lecturer.fromJson(body);
      } else {
        _handleApiError(response, 'Thêm giảng viên thất bại');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi thêm giảng viên: ${e.toString()}');
    }
  }

  Future<Lecturer> updateLecturer(int id, Lecturer lecturer) async {
    final Uri url = Uri.parse('$baseUrl/lecturers/$id');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(lecturer.toJson()),
      );
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        return Lecturer.fromJson(body);
      } else {
        _handleApiError(response, 'Cập nhật giảng viên thất bại');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi cập nhật giảng viên: ${e.toString()}');
    }
  }

  Future<void> deleteLecturer(int id) async {
    final Uri url = Uri.parse('$baseUrl/lecturers/$id');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleApiError(response, 'Xóa giảng viên thất bại');
      }
    } catch (e) {
      // 👇 SỬA LẠI KHỐI CATCH
      throw Exception('Lỗi kết nối khi xóa giảng viên: ${e.toString()}');
    }
  }

  Never _handleApiError(http.Response response, String defaultMessage) {
    try {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      if (error is Map && error.containsKey('message')) {
        if(error.containsKey('errors')) {
          final errors = error['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        throw Exception(error['message']);
      }
      throw Exception(error.toString());
    } catch (e) {
      if (e is FormatException || e is TypeError) {
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      rethrow;
    }
  }
}