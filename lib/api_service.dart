// file: lib/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Import models
import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../models/lecturer.dart';
import '../models/schedule.dart';
import '../models/room.dart'; // <-- ĐÃ THÊM
import '../models/class_course_assignment.dart'; // <-- ĐÃ THÊM
import 'models/pending_leave_request.dart';
// Import models từ thư mục table (cho User và HomeSummary)
import '../table/home_summary.dart';
import '../table/user.dart';

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
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- setToken ---
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
        if (responseBody.isEmpty) {
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
        if (responseBody.isEmpty) {
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

  // --- 👇 HÀM ĐƯỢC BỔ SUNG (HomeScreen cần) ---
  /// ---------------------------------------------------
  /// 👤 Fetch User By ID (Needed by HomeScreen)
  /// ---------------------------------------------------
  Future<User> fetchUserById(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if (responseBody.isEmpty) {
          throw Exception('Failed to load user: Empty response.');
        }
        // Giả sử API trả về { "data": { ...user... } }
        final data = jsonDecode(responseBody);
        return User.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Error loading user data');
      }
    } catch (e) {
      print("fetchUserById Error: $e");
      throw Exception('Lỗi kết nối khi tải người dùng: ${e.toString()}');
    }
  }
  // --- 👆 KẾT THÚC HÀM ĐƯỢC BỔ SUNG ---

  /// ---------------------------------------------------
  /// 👥 User Management
  /// ---------------------------------------------------
  Future<PaginatedUsersResponse> fetchUsers(int page,
      {String? searchQuery}) async {
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
        final List<dynamic> dataList =
        jsonDecode(utf8.decode(response.bodyBytes));
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
      final List<dynamic> dataList =
      jsonDecode(utf8.decode(response.bodyBytes));
      return dataList.map((item) => Room.fromJson(item)).toList();
    } else {
      _handleApiError(response, 'Error loading rooms');
    }
  }

  Future<List<ClassCourseAssignment>> fetchClassCourseAssignments() async {
    final Uri url = Uri.parse('$baseUrl/classcourseassignments');
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> dataList =
      jsonDecode(utf8.decode(response.bodyBytes));
      return dataList
          .map((item) => ClassCourseAssignment.fromJson(item))
          .toList();
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

  /// ---------------------------------------------------
  /// ⚠️ Error Handler
  /// ---------------------------------------------------
  // Never _handleApiError(http.Response response, String defaultMessage) {
  //   try {
  //     print(
  //         "API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
  //
  //     final error = jsonDecode(utf8.decode(response.bodyBytes));
  //     if (error is Map && error.containsKey('message')) {
  //       if (error.containsKey('errors')) {
  //         final errors = error['errors'] as Map;
  //         final firstError = errors.values.first;
  //         if (firstError is List && firstError.isNotEmpty) {
  //           throw Exception(firstError.first);
  //         }
  //       }
  //       throw Exception(error['message']);
  //     }
  //     throw Exception(error.toString());
  //   } catch (e) {
  //     if (e is FormatException || e is TypeError) {
  //       throw Exception('$defaultMessage (Code: ${response.statusCode})');
  //     }
  //     rethrow;
  //   }
  // }
  Future<List<PendingLeaveRequest>> fetchPendingLeaveRequests() async {
    // Giả sử API endpoint là /admin/leave-requests/pending
    final Uri url = Uri.parse('$baseUrl/admin/leave-requests/pending');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((item) => PendingLeaveRequest.fromJson(item)).toList();
      } else {
        return _handleApiError(response, 'Lỗi khi tải danh sách chờ duyệt');
      }
    } catch (e) {
      print("fetchPendingLeaveRequests Error: $e");
      rethrow;
    }
  }

  // 👈 THÊM 2: Duyệt (approve) đơn
  Future<void> approveLeaveRequest(int requestId) async {
    // Giả sử API endpoint là /admin/leave-requests/{id}/approve
    final Uri url = Uri.parse('$baseUrl/admin/leave-requests/$requestId/approve');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'status': 'approved'}), // Gửi kèm trạng thái mới
      );
      if (response.statusCode != 200) {
        _handleApiError(response, 'Lỗi khi duyệt đơn');
      }
    } catch (e) {
      print("approveLeaveRequest Error: $e");
      rethrow;
    }
  }

  // 👈 THÊM 3: Từ chối (reject) đơn
  Future<void> rejectLeaveRequest(int requestId) async {
    // Giả sử API endpoint là /admin/leave-requests/{id}/reject
    final Uri url = Uri.parse('$baseUrl/admin/leave-requests/$requestId/reject');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'status': 'rejected'}), // Gửi kèm trạng thái mới
      );
      if (response.statusCode != 200) {
        _handleApiError(response, 'Lỗi khi từ chối đơn');
      }
    } catch (e) {
      print("rejectLeaveRequest Error: $e");
      rethrow;
    }
  }


  /// ---------------------------------------------------
  /// ⚙️ Hàm xử lý lỗi API chung (Private Helper)
  /// ---------------------------------------------------
  Never _handleApiError(http.Response response, String defaultMessage) {
    print("API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
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
      if (e is FormatException) {
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      rethrow;
    }
  }
}