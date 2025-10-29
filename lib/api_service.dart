// file: lib/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'table/user.dart'; // Giả định đây là model User
import 'table/home_summary.dart'; // Giả định đây là model HomeSummary
import 'models/schedule.dart';
import 'models/lecturer.dart';
import 'models/department.dart'; // Import Department model

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
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void setToken(String token) {
    _token = token;
  }

  // Phương thức login
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
          _token = data['token']; // Lưu token
        }
        return user;
      } else {
        _handleApiError(response, 'Đăng nhập thất bại');
      }
    } catch (e) {
      rethrow;
    }
    return Future.error('Đăng nhập không thành công'); // Nên có return cuối cùng
  }

  // Phương thức fetchHomeSummary
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
      rethrow;
    }
    return Future.error('Lỗi tải dữ liệu trang chủ');
  }

  // Phương thức fetchSchedules
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
      rethrow;
    }
    return Future.error('Lỗi tải lịch học');
  }

  // Phương thức fetchLecturers (có thể API trả về phân trang, cần xử lý 'data' key)
  Future<List<Lecturer>> fetchLecturers() async {
    final Uri url = Uri.parse('$baseUrl/lecturers');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        // Kiểm tra nếu API trả về một đối tượng có khóa 'data' (ví dụ: cho phân trang)
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : body;
        return dataList.map((item) => Lecturer.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách giảng viên');
      }
    } catch (e) {
      rethrow;
    }
    return Future.error('Lỗi tải danh sách giảng viên');
  }

  // *** THÊM PHƯƠNG THỨC NÀY ĐỂ LẤY DANH SÁCH KHOA ***
  Future<List<Department>> fetchDepartments() async {
    final Uri url = Uri.parse('$baseUrl/departments'); // Giả định route API là /api/departments
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : body;
        return dataList.map((item) => Department.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách khoa');
      }
    } catch (e) {
      rethrow;
    }
    return Future.error('Lỗi tải danh sách khoa');
  }

  Never _handleApiError(http.Response response, String defaultMessage) {
    try {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['message'] ?? '$defaultMessage (Code: ${response.statusCode})');
    } catch (e) {
      if (e is FormatException || e is TypeError) {
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      rethrow;
    }
  }
}