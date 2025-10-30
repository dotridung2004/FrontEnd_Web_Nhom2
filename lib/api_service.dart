import 'dart:convert'; // For jsonEncode, jsonDecode, utf8
import 'package:flutter/foundation.dart' show kIsWeb; // For checking web platform
import 'package:http/http.dart' as http; // For making HTTP requests

// Import các model hiện có
import 'models/course.dart';
import 'models/class_course.dart';
import 'models/registered_course.dart';
import 'table/user.dart';
import 'table/home_summary.dart';
import 'models/schedule.dart';
import 'models/department.dart';
import 'models/room.dart';
import 'models/major.dart';
import 'models/division.dart';
import 'models/division_detail.dart';

// 👇 TẠO 1 CLASS MỚI ĐỂ CHỨA KẾT QUẢ PHÂN TRANG
class PaginatedDivisions {
  final List<Division> divisions;
  final int totalItems;
  final int currentPage;
  final int lastPage;

  PaginatedDivisions({
    required this.divisions,
    required this.totalItems,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginatedDivisions.fromJson(Map<String, dynamic> json) {
    List<Division> divisionsList = [];
    if (json['data'] != null && json['data'] is List) {
      divisionsList = (json['data'] as List)
          .map((item) => Division.fromJson(item)) // Đảm bảo Division.fromJson khớp
          .toList();
    }

    return PaginatedDivisions(
      divisions: divisionsList,
      // Đọc metadata từ Laravel pagination
      totalItems: json['total'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }
}
// 👆 KẾT THÚC CLASS MỚI


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
      // Dùng localhost cho web
      return 'http://localhost:8000/api';
    } else {
      // Dùng 10.0.2.2 cho Android Emulator
      return 'http://10.0.2.2:8000/api';
    }
  }
  // --- End Base URL Configuration ---

  String? _token; // Lưu token xác thực

  // Helper tạo header cho request
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

  // ===================================================
  // Các hàm API hiện có (login, fetchHomeSummary, etc.)
  // ===================================================
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
          print("Đăng nhập thành công, Token đã lưu!");
        } else {
          print("Cảnh báo: Đăng nhập thành công nhưng không nhận được token.");
        }

        if (user.status == 'active') {
          return user;
        } else {
          throw Exception('❌ Tài khoản của bạn đã bị vô hiệu hóa.');
        }
      } else {
        _handleApiError(response, 'Đăng nhập thất bại');
      }
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ.');
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
      print("fetchHomeSummary Lỗi: $e");
      rethrow;
    }
  }

  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else if (body is List) {
          dataList = body;
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lịch học');
      }
    } catch (e) {
      print("fetchSchedules Lỗi: $e");
      rethrow;
    }
  }

  Future<List<Course>> fetchCourses() async {
    final Uri url = Uri.parse('$baseUrl/courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else if (body is List) {
          dataList = body;
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => Course.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách học phần');
      }
    } catch (e) {
      print("fetchCourses Lỗi: $e");
      rethrow;
    }
  }

  Future<List<ClassCourse>> fetchClassCourses() async {
    final Uri url = Uri.parse('$baseUrl/class-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else if (body is List) {
          dataList = body;
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => ClassCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp học phần');
      }
    } catch (e) {
      print("fetchClassCourses Lỗi: $e");
      rethrow;
    }
  }

  Future<List<RegisteredCourse>> fetchRegisteredCourses() async {
    final Uri url = Uri.parse('$baseUrl/registered-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;

        if (body is List) {
          dataList = body;
        } else if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => RegisteredCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp đã đăng ký');
      }
    } catch (e) {
      print("fetchRegisteredCourses Lỗi: $e");
      rethrow;
    }
  }

  Future<List<Department>> fetchDepartments() async {
    final Uri url = Uri.parse('$baseUrl/departments');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is List) {
          dataList = body;
        } else if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => Department.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách khoa');
      }
    } catch (e) {
      print("fetchDepartments Lỗi: $e");
      rethrow;
    }
  }

  Future<List<Room>> fetchRooms() async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is List) {
          dataList = body;
        } else if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => Room.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách phòng học');
      }
    } catch (e) {
      print("fetchRooms Lỗi: $e");
      rethrow;
    }
  }

  Future<List<Major>> fetchMajors() async {
    final Uri url = Uri.parse('$baseUrl/majors');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList;
        if (body is List) {
          dataList = body;
        } else if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else {
          throw Exception('Định dạng dữ liệu không hợp lệ');
        }
        return dataList.map((item) => Major.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách ngành học');
      }
    } catch (e) {
      print("fetchMajors Lỗi: $e");
      rethrow;
    }
  }

  // 👇 **** BẮT ĐẦU SỬA ĐỔI fetchDivisions **** 👇
  /// ---------------------------------------------------
  /// 🔬 Division Management - Fetch List (CÓ PHÂN TRANG & TÌM KIẾM)
  /// ---------------------------------------------------
  Future<PaginatedDivisions> fetchDivisions({int page = 1, String query = ''}) async {
    // Xây dựng URL với tham số page và search (đã encode)
    final Uri url = Uri.parse('$baseUrl/divisions?page=$page&search=${Uri.encodeComponent(query)}');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));

        // Trả về đối tượng PaginatedDivisions
        return PaginatedDivisions.fromJson(body);
      } else {
        _handleApiError(response, 'Lỗi tải danh sách bộ môn');
      }
    } catch (e) {
      print("fetchDivisions Lỗi: $e");
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }
  // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

  // ===================================================
  // 👇 CRUD BỘ MÔN (DIVISION) 👇
  // ===================================================

  /// ---------------------------------------------------
  /// 🔬 Division Management - Fetch Details
  /// ---------------------------------------------------
  Future<DivisionDetail> fetchDivisionDetails(int divisionId) async {
    final Uri url = Uri.parse('$baseUrl/divisions/$divisionId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return DivisionDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết bộ môn');
      }
    } catch (e) {
      print("fetchDivisionDetails Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🔬 Division Management - Create
  /// ---------------------------------------------------
  Future<Division> createDivision(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/divisions');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) { // 201 Created
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        // Backend (hàm store) đã map sẵn dữ liệu, nên parse trực tiếp
        return Division.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi tạo bộ môn');
      }
    } catch (e) {
      print("createDivision Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🔬 Division Management - Update
  /// ---------------------------------------------------
  Future<Division> updateDivision(int divisionId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/divisions/$divisionId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) { // 200 OK
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        // Backend (hàm update) đã map sẵn dữ liệu
        return Division.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi cập nhật bộ môn');
      }
    } catch (e) {
      print("updateDivision Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🔬 Division Management - Delete
  /// ---------------------------------------------------
  Future<void> deleteDivision(int divisionId) async {
    final Uri url = Uri.parse('$baseUrl/divisions/$divisionId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa bộ môn');
      }
    } catch (e) {
      print("deleteDivision Lỗi: $e");
      rethrow;
    }
  }
  /// ---------------------------------------------------
  /// 🔬 Department Management - Create
  /// ---------------------------------------------------
  Future<Department> createDepartment(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/departments');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) { // 201 Created
        return Department.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tạo khoa');
      }
    } catch (e) {
      print("createDepartment Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🔬 Department Management - Update
  /// ---------------------------------------------------
  Future<Department> updateDepartment(int departmentId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) { // 200 OK
        return Department.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi cập nhật khoa');
      }
    } catch (e) {
      print("updateDepartment Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🔬 Department Management - Delete
  /// ---------------------------------------------------
  Future<void> deleteDepartment(int departmentId) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) { // 204 No Content
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa khoa');
      }
    } catch (e) {
      print("deleteDepartment Lỗi: $e");
      rethrow;
    }
  }
  // ===================================================
  // Private Helper Methods
  // ===================================================
  Never _handleApiError(http.Response response, String defaultMessage) {
    print(
        "Lỗi API (${response.request?.url}): ${response.statusCode} - ${response.body}");
    try {
      final errorBody = utf8.decode(response.bodyBytes);
      if (errorBody.isEmpty) {
        throw Exception('$defaultMessage (Mã lỗi: ${response.statusCode})');
      }
      final error = jsonDecode(errorBody);
      throw Exception(
          error['message'] ?? '$defaultMessage (Mã lỗi: ${response.statusCode})');
    } catch (e) {
      if (e is FormatException || e is TypeError || e is Exception) {
        throw Exception('$defaultMessage (Mã lỗi: ${response.statusCode}) - Phản hồi: ${utf8.decode(response.bodyBytes)}');
      }
      rethrow;
    }
  }
} // End of ApiService class