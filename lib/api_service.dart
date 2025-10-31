import 'dart:convert'; // For jsonEncode, jsonDecode, utf8
import 'package:flutter/foundation.dart' show kIsWeb; // For checking web platform
import 'package:http/http.dart' as http; // For making HTTP requests
import 'package:intl/intl.dart'; // For date formatting

// Đảm bảo đường dẫn đến model của bạn là chính xác
import 'models/schedule.dart'; // <<< *** PHẢI CẬP NHẬT MODEL NÀY ***
import 'table/user.dart';
import 'table/home_summary.dart';

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
  // Thêm các trường khác nếu cần để hiển thị hoặc lọc
  ClassCourseAssignment({required this.id, required this.displayName});
  factory ClassCourseAssignment.fromJson(Map<String, dynamic> json) {
    return ClassCourseAssignment(
        id: json['id'],
        displayName: json['display_name'] ?? 'N/A'
    );
  }
}


class ApiService {
  // --- Singleton Pattern ---
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }
  // --- End Singleton Pattern ---

  // --- Base URL Configuration ---
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }
  // --- End Base URL Configuration ---

  // --- Authentication Token ---
  String? _token;
  // --- End Authentication Token ---

  // --- Helper for HTTP Headers ---
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
  // --- End Helper for HTTP Headers ---

  // ===================================================
  // API Methods
  // ===================================================

  /// ---------------------------------------------------
  /// 👤 Authentication: Login
  /// ---------------------------------------------------
  Future<User> login(String email, String password) async {
    // ... (Giữ nguyên)
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
          _token = data['token'];
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
  /// 🏠 Home Screen Data (Admin/Teacher)
  /// ---------------------------------------------------
  Future<HomeSummary> fetchHomeSummary(int userId) async {
    // ... (Giữ nguyên)
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
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management - Fetch List (READ) - ĐÃ SỬA
  /// ---------------------------------------------------
  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        // ScheduleController::index() đã map dữ liệu, nên đây là List trực tiếp
        final List<dynamic> dataList = jsonDecode(utf8.decode(response.bodyBytes));

        // *** QUAN TRỌNG: Model Schedule.fromJson PHẢI được cập nhật ***
        // để đọc các key tiếng Anh (teacherName, classCode,...)
        // VÀ các ID (id, room_id, class_course_assignment_id, date, session)
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading schedule list');
      }
    } catch (e) {
      print("fetchSchedules Error: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 📚 Fetch Rooms (MỚI)
  /// ---------------------------------------------------
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

  /// ---------------------------------------------------
  /// 🧑‍🏫 Fetch Class Course Assignments (MỚI)
  /// ---------------------------------------------------
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


  /// ---------------------------------------------------
  /// 🗓️ Schedule Management - Create (CREATE) - ĐÃ SỬA
  /// ---------------------------------------------------
  Future<void> createSchedule(Map<String, dynamic> scheduleData) async {
    // scheduleData bây giờ phải chứa ID:
    // { 'class_course_assignment_id': ..., 'room_id': ..., 'date': 'Y-m-d', 'session': '...' }
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(scheduleData), // Gửi map chứa ID
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return; // Tạo thành công
      } else {
        _handleApiError(response, 'Error creating schedule');
      }
    } catch (e) {
      print("createSchedule Error: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management - Update (UPDATE) - ĐÃ SỬA
  /// ---------------------------------------------------
  Future<void> updateSchedule(
      int scheduleId, Map<String, dynamic> scheduleData) async {
    // scheduleData cũng phải chứa ID
    final Uri url = Uri.parse('$baseUrl/schedules/$scheduleId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(scheduleData), // Gửi map chứa ID
      );
      if (response.statusCode == 200) {
        return; // Cập nhật thành công
      } else {
        _handleApiError(response, 'Error updating schedule');
      }
    } catch (e) {
      print("updateSchedule Error: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management - Delete (DELETE)
  /// ---------------------------------------------------
  Future<void> deleteSchedule(int scheduleId) async {
    // ... (Giữ nguyên)
    final Uri url = Uri.parse('$baseUrl/schedules/$scheduleId');
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return; // Xóa thành công
      } else {
        _handleApiError(response, 'Error deleting schedule');
      }
    } catch (e) {
      print("deleteSchedule Error: $e");
      rethrow;
    }
  }

  // ... (Giữ nguyên hàm _handleApiError)
  Never _handleApiError(http.Response response, String defaultMessage) {
    print(
        "API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
    final String responseBody = utf8.decode(response.bodyBytes);
    if(responseBody.isEmpty) {
      throw Exception('$defaultMessage (Code: ${response.statusCode})');
    }
    try {
      final error = jsonDecode(responseBody);
      throw Exception(
          error['message'] ?? '$defaultMessage (Code: ${response.statusCode})');
    } catch (e) {
      if (e is FormatException || e is TypeError) {
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      rethrow;
    }
  }
}