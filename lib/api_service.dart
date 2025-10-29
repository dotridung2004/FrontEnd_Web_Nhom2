// lib/api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// <<< THÊM IMPORT CHO CÁC MODEL BẠN SỬ DỤNG
import 'table/user.dart';
import 'table/home_summary.dart';
import 'models/schedule.dart';
import 'models/lecturer.dart';
import 'models/department.dart';

class ApiService {
  // --- Cấu trúc Singleton để chỉ có 1 instance của ApiService ---
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }

  // --- Base URL cho API ---
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }

  String? _token;

  // --- Lấy Headers cho request, có hoặc không có token ---
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

  void setToken(String token) {
    _token = token;
  }

  // --- Các hàm API khác của bạn ---
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
          _token = data['token'];
        }
        return user;
      } else {
        _handleApiError(response, 'Đăng nhập thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

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
  }

  // <<< HÀM fetchSchedules ĐÃ ĐƯỢC THÊM VÀO ĐÂY
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
  }

  // --- CÁC HÀM API CHO GIẢNG VIÊN (LECTURER) ---

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
      rethrow;
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
      if (response.statusCode == 201) { // 201 Created
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        return Lecturer.fromJson(body);
      } else {
        _handleApiError(response, 'Thêm giảng viên thất bại');
      }
    } catch (e) {
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }


  // --- Hàm xử lý lỗi chung ---
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