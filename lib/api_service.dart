// lib/table/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../models/lecturer.dart';
import '../models/schedule.dart';
import '../models/report_data.dart'; // <<< 1. THÊM IMPORT CHO MODEL BÁO CÁO
import '../table/home_summary.dart';
import '../table/user.dart';

// (VÍ DỤ) Model đơn giản cho Room
class Room {
  final int id;
  final String name;
  Room({required this.id, required this.name});
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(id: json['id'], name: json['name'] ?? 'N/A');
  }
}

// (VÍ DỤ) Model đơn giản cho ClassCourseAssignment
class ClassCourseAssignment {
  final int id;
  final String displayName;
  ClassCourseAssignment({required this.id, required this.displayName});
  factory ClassCourseAssignment.fromJson(Map<String, dynamic> json) {
    return ClassCourseAssignment(
        id: json['id'],
        displayName: json['display_name'] ?? 'N/A'
    );
  }
}


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

  // ===================================================
  // API Methods
  // ===================================================

  /// ---------------------------------------------------
  /// 👤 Authentication: Login
  /// ---------------------------------------------------
  Future<User> login(String email, String password) async {
    final Uri loginUrl = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        loginUrl,
        headers: _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final String responseBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        if(responseBody.isEmpty) {
          throw Exception('Login successful but no user data received.');
        }
        final data = jsonDecode(responseBody);
        final User user = User.fromJson(data['user']);

        if (data['token'] != null) {
          setToken(data['token']);
          print("Login successful, Token stored!");
        } else {
          print("Warning: Login successful but no token received.");
        }

        if (user.status == 'active') {
          return user;
        } else {
          throw Exception('❌ Your account has been disabled.');
        }
      } else {
        _handleApiError(response, 'Login failed');
      }
    } catch (e) {
      print("Login Error: $e");
      if (e is Exception) rethrow;
      throw Exception('Could not connect to the server.');
    }
  }

  /// ---------------------------------------------------
  /// 🏠 Home Screen Data
  /// ---------------------------------------------------
  Future<HomeSummary> fetchHomeSummary(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId/home-summary');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if(responseBody.isEmpty) {
          throw Exception('Failed to load home summary: Empty response.');
        }
        return HomeSummary.fromJson(jsonDecode(responseBody));
      } else {
        _handleApiError(response, 'Error loading home data');
      }
    } catch (e) {
      print("fetchHomeSummary Error: $e");
      throw Exception('Lỗi kết nối khi tải trang chủ: ${e.toString()}');
    }
  }

  /// ---------------------------------------------------
  /// 👥 User Management
  /// ---------------------------------------------------
  Future<PaginatedUsersResponse> fetchUsers(int page, {String? searchQuery}) async {
    final Uri baseUri = Uri.parse('$baseUrl/users');
    final Map<String, String> queryParameters = {
      'page': page.toString(),
      if (searchQuery != null && searchQuery.isNotEmpty) 'name': searchQuery,
    };
    final Uri url = baseUri.replace(queryParameters: queryParameters);

    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return PaginatedUsersResponse.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi tải danh sách tài khoản');
      }
    } catch (e) {
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

  /// ---------------------------------------------------
  /// 👨‍🏫 Lecturer Management
  /// ---------------------------------------------------
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
      throw Exception('Lỗi kết nối khi xóa giảng viên: ${e.toString()}');
    }
  }

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management
  /// ---------------------------------------------------
  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(utf8.decode(response.bodyBytes));
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading schedule list');
      }
    } catch (e) {
      print("fetchSchedules Error: $e");
      rethrow;
    }
  }

  Future<List<Room>> fetchRooms() async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> dataList = jsonDecode(utf8.decode(response.bodyBytes));
      return dataList.map((item) => Room.fromJson(item)).toList();
    } else {
      _handleApiError(response, 'Error loading rooms');
    }
  }

  Future<List<ClassCourseAssignment>> fetchClassCourseAssignments() async {
    final Uri url = Uri.parse('$baseUrl/classcourseassignments');
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> dataList = jsonDecode(utf8.decode(response.bodyBytes));
      return dataList.map((item) => ClassCourseAssignment.fromJson(item)).toList();
    } else {
      _handleApiError(response, 'Error loading assignments');
    }
  }

  Future<void> createSchedule(Map<String, dynamic> scheduleData) async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(scheduleData),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Error creating schedule');
      }
    } catch (e) {
      print("createSchedule Error: $e");
      rethrow;
    }
  }

  Future<void> updateSchedule(
      int scheduleId, Map<String, dynamic> scheduleData) async {
    final Uri url = Uri.parse('$baseUrl/schedules/$scheduleId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(scheduleData),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Error updating schedule');
      }
    } catch (e) {
      print("updateSchedule Error: $e");
      rethrow;
    }
  }

  Future<void> deleteSchedule(int scheduleId) async {
    final Uri url = Uri.parse('$baseUrl/schedules/$scheduleId');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(),
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Error deleting schedule');
      }
    } catch (e) {
      print("deleteSchedule Error: $e");
      rethrow;
    }
  }

  // --- 👇 2. THÊM HÀM MỚI VÀO ĐÂY ---
  /// ---------------------------------------------------
  /// 📊 Report Data
  /// ---------------------------------------------------
  Future<ReportData> fetchReportData({String? semester, int? departmentId}) async {
    final Map<String, String> queryParameters = {};
    if (semester != null) queryParameters['semester'] = semester;
    if (departmentId != null) queryParameters['department_id'] = departmentId.toString();

    final Uri url = Uri.parse('$baseUrl/reports/overview').replace(queryParameters: queryParameters);
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if(responseBody.isEmpty) {
          throw Exception('Failed to load report data: Empty response.');
        }
        return ReportData.fromJson(jsonDecode(responseBody));
      } else {
        _handleApiError(response, 'Error loading report data');
      }
    } catch (e) {
      print("fetchReportData Error: $e");
      throw Exception('Lỗi kết nối khi tải dữ liệu báo cáo: ${e.toString()}');
    }
  }

  /// ---------------------------------------------------
  /// ⚠️ Error Handler
  /// ---------------------------------------------------
  Never _handleApiError(http.Response response, String defaultMessage) {
    try {
      print("API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");

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