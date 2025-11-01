// Tên file: lib/services/api_service.dart
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
import 'models/department_detail.dart';
import 'models/room.dart';
import 'models/major.dart'; // Model cho danh sách
import 'models/division.dart';
import 'models/division_detail.dart';
import 'models/major_detail.dart'; // Model cho chi tiết
import 'models/room_detail.dart'; // <-- THÊM MỚI
import 'models/course_detail.dart';
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
  // API XÁC THỰC & CHUNG
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
        if (data['token'] != null) { _token = data['token']; }
        if (user.status == 'active') { return user; }
        else { throw Exception('❌ Tài khoản của bạn đã bị vô hiệu hóa.'); }
      } else { _handleApiError(response, 'Đăng nhập thất bại'); }
    } catch (e) { rethrow; }
  }

  Future<HomeSummary> fetchHomeSummary(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId/home-summary');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return HomeSummary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else { _handleApiError(response, 'Lỗi tải dữ liệu trang chủ'); }
    } catch (e) { rethrow; }
  }

  // ===================================================
  // API TẢI DANH SÁCH (CHO CÁC MÀN HÌNH)
  // ===================================================

  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lịch học');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Course>> fetchCourses() async {
    final Uri url = Uri.parse('$baseUrl/courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => Course.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách học phần');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClassCourse>> fetchClassCourses() async {
    final Uri url = Uri.parse('$baseUrl/class-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => ClassCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp học phần');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RegisteredCourse>> fetchRegisteredCourses() async {
    final Uri url = Uri.parse('$baseUrl/registered-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => RegisteredCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp đã đăng ký');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Room>> fetchRooms() async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => Room.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách phòng học');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===================================================
  // 🔬 QUẢN LÝ KHOA (DEPARTMENT)
  // ===================================================
  Future<List<Department>> fetchDepartments() async {
    final Uri url = Uri.parse('$baseUrl/departments');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        return dataList.map((item) => Department.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách khoa');
      }
    } catch (e) {
      print("fetchDepartments Lỗi: $e");
      rethrow;
    }
  }

  Future<DepartmentDetail> fetchDepartmentDetails(int departmentId) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId/details');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return DepartmentDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết khoa');
      }
    } catch (e) {
      print("fetchDepartmentDetails Lỗi: $e");
      rethrow;
    }
  }

  Future<Department> createDepartment(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/departments');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Department.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tạo khoa');
      }
    } catch (e) {
      print("createDepartment Lỗi: $e");
      rethrow;
    }
  }

  Future<Department> updateDepartment(int departmentId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return Department.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi cập nhật khoa');
      }
    } catch (e) {
      print("updateDepartment Lỗi: $e");
      rethrow;
    }
  }

  Future<void> deleteDepartment(int departmentId) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
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
  // 🔬 QUẢN LÝ BỘ MÔN (DIVISION)
  // ===================================================
  Future<List<Division>> fetchDivisions() async {
    final Uri url = Uri.parse('$baseUrl/divisions');
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
        return dataList.map((item) => Division.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách bộ môn');
      }
    } catch (e) {
      print("fetchDivisions Lỗi: $e");
      rethrow;
    }
  }

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

  Future<Division> createDivision(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/divisions');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return Division.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi tạo bộ môn');
      }
    } catch (e) {
      print("createDivision Lỗi: $e");
      rethrow;
    }
  }

  Future<Division> updateDivision(int divisionId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/divisions/$divisionId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return Division.fromJson(responseData);
      } else {
        _handleApiError(response, 'Lỗi cập nhật bộ môn');
      }
    } catch (e) {
      print("updateDivision Lỗi: $e");
      rethrow;
    }
  }

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

  // ===================================================
  // 🔬 QUẢN LÝ NGÀNH HỌC (MAJOR)
  // ===================================================
  Future<List<Major>> fetchMajors() async {
    final Uri url = Uri.parse('$baseUrl/majors');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> && body.containsKey('data')) ? body['data'] : (body is List ? body : []);
        List<Major> majors = dataList.map((item) => Major.fromJson(item)).toList();
        return majors;
      } else {
        _handleApiError(response, 'Lỗi tải danh sách ngành học');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MajorDetail> fetchMajorDetails(int majorId) async {
    final Uri url = Uri.parse('$baseUrl/majors/$majorId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return MajorDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết ngành học');
      }
    } catch (e) {
      print("fetchMajorDetails Lỗi: $e");
      rethrow;
    }
  }

  Future<Major> createMajor(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/majors');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Major.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tạo ngành học');
      }
    } catch (e) {
      print("createMajor Lỗi: $e");
      rethrow;
    }
  }

  Future<Major> updateMajor(int majorId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/majors/$majorId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return Major.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi cập nhật ngành học');
      }
    } catch (e) {
      print("updateMajor Lỗi: $e");
      rethrow;
    }
  }

  Future<void> deleteMajor(int majorId) async {
    final Uri url = Uri.parse('$baseUrl/majors/$majorId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa ngành học');
      }
    } catch (e) {
      print("deleteMajor Lỗi: $e");
      rethrow;
    }
  }

  // ===================================================
  // 🔬 QUẢN LÝ PHÒNG HỌC (ROOM) - (PHẦN MỚI)
  // ===================================================

  /// Tạo mới phòng học
  Future<Room> createRoom(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) {
        return Room.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tạo phòng học');
      }
    } catch (e) {
      print("createRoom Lỗi: $e");
      rethrow;
    }
  }

  /// Cập nhật phòng học
  Future<Room> updateRoom(int roomId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/rooms/$roomId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return Room.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi cập nhật phòng học');
      }
    } catch (e) {
      print("updateRoom Lỗi: $e");
      rethrow;
    }
  }

  /// Xóa phòng học
  Future<void> deleteRoom(int roomId) async {
    final Uri url = Uri.parse('$baseUrl/rooms/$roomId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa phòng học');
      }
    } catch (e) {
      print("deleteRoom Lỗi: $e");
      rethrow;
    }
  }

  /// Tải chi tiết 1 phòng học
  Future<RoomDetail> fetchRoomDetails(int roomId) async {
    final Uri url = Uri.parse('$baseUrl/rooms/$roomId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return RoomDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết phòng học');
      }
    } catch (e) {
      print("fetchRoomDetails Lỗi: $e");
      rethrow;
    }
  }
// ===================================================
  // 🔬 QUẢN LÝ HỌC PHẦN (COURSE) - (PHẦN MỚI)
  // ===================================================

  /// Tải chi tiết 1 học phần (cho popup xem/sửa)
  Future<CourseDetail> fetchCourseDetails(int courseId) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId'); // Giả sử endpoint là /courses/{id}
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return CourseDetail.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết học phần');
      }
    } catch (e) {
      print("fetchCourseDetails Lỗi: $e");
      rethrow;
    }
  }

  /// Tạo mới học phần
  Future<void> createCourse(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/courses');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return; // Thành công
      } else {
        _handleApiError(response, 'Lỗi tạo học phần');
      }
    } catch (e) {
      print("createCourse Lỗi: $e");
      rethrow;
    }
  }

  /// Cập nhật học phần
  Future<void> updateCourse(int courseId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return; // Thành công
      } else {
        _handleApiError(response, 'Lỗi cập nhật học phần');
      }
    } catch (e) {
      print("updateCourse Lỗi: $e");
      rethrow;
    }
  }

  /// Xóa học phần
  Future<void> deleteCourse(int courseId) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return; // Thành công
      } else {
        _handleApiError(response, 'Lỗi xóa học phần');
      }
    } catch (e) {
      print("deleteCourse Lỗi: $e");
      rethrow;
    }
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
// End of ApiService class