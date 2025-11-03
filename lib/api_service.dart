import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// --- Import Models (Gộp từ cả 2 tệp) ---

// Các model chung & từ Tệp 1
import '../models/app_user.dart';
import '../models/paginated_response.dart'; // Giả sử là PaginatedUsersResponse
import '../models/lecturer.dart';
import '../models/schedule.dart';
import '../models/room.dart';
import '../models/class_course_assignment.dart';
import '../models/pending_leave_request.dart';
import '../table/home_summary.dart';
import '../table/user.dart';

// Các model từ Tệp 2
import '../models/course.dart';
import '../models/class_course.dart';
import '../models/registered_course.dart';
import '../models/department.dart';
import '../models/department_detail.dart';
import '../models/major.dart';
import '../models/division.dart';
import '../models/division_detail.dart';
import '../models/major_detail.dart';
import '../models/room_detail.dart';
import '../models/course_detail.dart';
import '../models/class_course_detail.dart';
import '../models/class_model.dart';
import '../models/class_course_form_data.dart';

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
      // 10.0.2.2 là địa chỉ IP đặc biệt cho Android Emulator để truy cập localhost của máy host
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

  // --- setToken (Từ Tệp 1) ---
  void setToken(String? token) {
    _token = token;
    if (token != null) {
      print("ApiService: Token has been set.");
    } else {
      print("ApiService: Token has been cleared.");
    }
  }

  // ===================================================
  // 👤 AUTHENTICATION & HOME
  // ===================================================

  /// ---------------------------------------------------
  /// 👤 Authentication: Login (Phiên bản Tệp 1 - đầy đủ hơn)
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
          throw Exception('Đăng nhập thành công nhưng không nhận được dữ liệu người dùng.');
        }
        final data = jsonDecode(responseBody);
        final User user = User.fromJson(data['user']);

        if (data['token'] != null) {
          setToken(data['token']); // Sử dụng setToken
        } else {
          print("Warning: Đăng nhập thành công nhưng không có token.");
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
      print("Login Error: $e");
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  /// ---------------------------------------------------
  /// 🏠 Home Screen Data (Phiên bản Tệp 1 - đầy đủ hơn)
  /// ---------------------------------------------------
  Future<HomeSummary> fetchHomeSummary(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId/home-summary');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if (responseBody.isEmpty) {
          throw Exception('Lỗi tải trang chủ: Phản hồi rỗng.');
        }
        return HomeSummary.fromJson(jsonDecode(responseBody));
      } else {
        _handleApiError(response, 'Lỗi tải dữ liệu trang chủ');
      }
    } catch (e) {
      print("fetchHomeSummary Error: $e");
      throw Exception('Lỗi kết nối khi tải trang chủ: ${e.toString()}');
    }
  }

  /// ---------------------------------------------------
  /// 👤 Fetch User By ID (Từ Tệp 1)
  /// ---------------------------------------------------
  Future<User> fetchUserById(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        if (responseBody.isEmpty) {
          throw Exception('Lỗi tải người dùng: Phản hồi rỗng.');
        }
        // Giả sử API trả về { "data": { ...user... } } hoặc chỉ { ...user... }
        final data = jsonDecode(responseBody);
        return User.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tải dữ liệu người dùng');
      }
    } catch (e) {
      print("fetchUserById Error: $e");
      throw Exception('Lỗi kết nối khi tải người dùng: ${e.toString()}');
    }
  }

  // ===================================================
  // 👥 USER & LECTURER MANAGEMENT (TỪ TỆP 1)
  // ===================================================

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
        // Xử lý cả 2 trường hợp: { "data": ... } hoặc chỉ { ... }
        return AppUser.fromJson(responseData['data'] ?? responseData);
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
        // Xử lý cả 2 trường hợp: { "data": ... } hoặc chỉ { ... }
        return AppUser.fromJson(responseData['data'] ?? responseData);
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
        // Chuẩn hóa logic tải danh sách (từ Tệp 2)
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => Lecturer.fromJson(item)).toList();
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
        return Lecturer.fromJson(body['data'] ?? body);
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
        return Lecturer.fromJson(body['data'] ?? body);
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

  // ===================================================
  // 🏛️ ORGANIZATIONAL MANAGEMENT (TỪ TỆP 2)
  // ===================================================

  /// ---------------------------------------------------
  /// 🏢 Departments
  /// ---------------------------------------------------
  Future<List<Department>> fetchDepartments() async {
    final Uri url = Uri.parse('$baseUrl/departments');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return DepartmentDetail.fromJson(data['data'] ?? data);
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Department.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tạo khoa');
      }
    } catch (e) {
      print("createDepartment Lỗi: $e");
      rethrow;
    }
  }

  Future<Department> updateDepartment(
      int departmentId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/departments/$departmentId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Department.fromJson(data['data'] ?? data);
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

  /// ---------------------------------------------------
  /// 🔬 Divisions
  /// ---------------------------------------------------
  Future<List<Division>> fetchDivisions() async {
    final Uri url = Uri.parse('$baseUrl/divisions');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return DivisionDetail.fromJson(data['data'] ?? data);
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
        return Division.fromJson(responseData['data'] ?? responseData);
      } else {
        _handleApiError(response, 'Lỗi tạo bộ môn');
      }
    } catch (e) {
      print("createDivision Lỗi: $e");
      rethrow;
    }
  }

  Future<Division> updateDivision(
      int divisionId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/divisions/$divisionId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return Division.fromJson(responseData['data'] ?? responseData);
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

  /// ---------------------------------------------------
  /// 🎓 Majors
  /// ---------------------------------------------------
  Future<List<Major>> fetchMajors() async {
    final Uri url = Uri.parse('$baseUrl/majors');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => Major.fromJson(item)).toList();
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return MajorDetail.fromJson(data['data'] ?? data);
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Major.fromJson(data['data'] ?? data);
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Major.fromJson(data['data'] ?? data);
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
  // 📚 ACADEMIC MANAGEMENT (GỘP TỪ 2 TỆP)
  // ===================================================

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management (Logic list Tệp 2, CRUD Tệp 1)
  /// ---------------------------------------------------
  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lịch học');
      }
    } catch (e) {
      print("fetchSchedules Error: $e");
      rethrow;
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
        _handleApiError(response, 'Lỗi tạo lịch học');
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
        _handleApiError(response, 'Lỗi cập nhật lịch học');
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
        _handleApiError(response, 'Lỗi xóa lịch học');
      }
    } catch (e) {
      print("deleteSchedule Error: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 🏫 Room Management (Logic list Tệp 2, CRUD/Details Tệp 2)
  /// ---------------------------------------------------
  Future<List<Room>> fetchRooms() async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => Room.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách phòng học');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<RoomDetail> fetchRoomDetails(int roomId) async {
    final Uri url = Uri.parse('$baseUrl/rooms/$roomId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return RoomDetail.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết phòng học');
      }
    } catch (e) {
      print("fetchRoomDetails Lỗi: $e");
      rethrow;
    }
  }

  Future<Room> createRoom(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Room.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tạo phòng học');
      }
    } catch (e) {
      print("createRoom Lỗi: $e");
      rethrow;
    }
  }

  Future<Room> updateRoom(int roomId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/rooms/$roomId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Room.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi cập nhật phòng học');
      }
    } catch (e) {
      print("updateRoom Lỗi: $e");
      rethrow;
    }
  }

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

  /// ---------------------------------------------------
  /// 📘 Course Management (Từ Tệp 2)
  /// ---------------------------------------------------
  Future<List<Course>> fetchCourses() async {
    final Uri url = Uri.parse('$baseUrl/courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => Course.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách học phần');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<CourseDetail> fetchCourseDetails(int courseId) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return CourseDetail.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết học phần');
      }
    } catch (e) {
      print("fetchCourseDetails Lỗi: $e");
      rethrow;
    }
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/courses');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi tạo học phần');
      }
    } catch (e) {
      print("createCourse Lỗi: $e");
      rethrow;
    }
  }

  Future<void> updateCourse(int courseId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi cập nhật học phần');
      }
    } catch (e) {
      print("updateCourse Lỗi: $e");
      rethrow;
    }
  }

  Future<void> deleteCourse(int courseId) async {
    final Uri url = Uri.parse('$baseUrl/courses/$courseId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa học phần');
      }
    } catch (e) {
      print("deleteCourse Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// 📚 Class Course Management (Từ Tệp 2)
  /// ---------------------------------------------------
  Future<List<ClassCourse>> fetchClassCourses() async {
    final Uri url = Uri.parse('$baseUrl/class-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList.map((item) => ClassCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp học phần');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ClassCourseDetail> fetchClassCourseDetails(int classCourseId) async {
    final Uri url = Uri.parse('$baseUrl/class-courses/$classCourseId/details');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassCourseDetail.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tải chi tiết lớp học phần');
      }
    } catch (e) {
      print("fetchClassCourseDetails Lỗi: $e");
      rethrow;
    }
  }

  Future<ClassCourse> createClassCourse(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/class-courses');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassCourse.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi tạo lớp học phần');
      }
    } catch (e) {
      print("createClassCourse Lỗi: $e");
      rethrow;
    }
  }

  Future<ClassCourse> updateClassCourse(
      int classCourseId, Map<String, dynamic> data) async {
    final Uri url = Uri.parse('$baseUrl/class-courses/$classCourseId');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassCourse.fromJson(data['data'] ?? data);
      } else {
        _handleApiError(response, 'Lỗi cập nhật lớp học phần');
      }
    } catch (e) {
      print("updateClassCourse Lỗi: $e");
      rethrow;
    }
  }

  Future<void> deleteClassCourse(int classCourseId) async {
    final Uri url = Uri.parse('$baseUrl/class-courses/$classCourseId');
    try {
      final response = await http.delete(url, headers: _getHeaders());
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else {
        _handleApiError(response, 'Lỗi xóa lớp học phần');
      }
    } catch (e) {
      print("deleteClassCourse Lỗi: $e");
      rethrow;
    }
  }

  Future<ClassCourseFormData> fetchClassCourseFormData() async {
    final Uri url = Uri.parse('$baseUrl/class-courses/form-data');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ClassCourseFormData.fromJson(data);
      } else {
        _handleApiError(response, 'Lỗi tải dữ liệu cho form');
      }
    } catch (e) {
      print("fetchClassCourseFormData Lỗi: $e");
      rethrow;
    }
  }

  /// ---------------------------------------------------
  /// ✍️ Other Academic Fetches (Gộp)
  /// ---------------------------------------------------

  // Từ Tệp 1 (Dùng cho Schedule) - ĐÃ CHUẨN HÓA LOGIC LIST
  Future<List<ClassCourseAssignment>> fetchClassCourseAssignments() async {
    final Uri url = Uri.parse('$baseUrl/class-courses');
    final response = await http.get(url, headers: _getHeaders());
    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
      List<dynamic> dataList = (body is Map<String, dynamic> &&
          body.containsKey('data'))
          ? body['data']
          : (body is List ? body : []);
      return dataList
          .map((item) => ClassCourseAssignment.fromJson(item))
          .toList();
    } else {
      _handleApiError(response, 'Lỗi tải danh sách phân công');
    }
  }

  // Từ Tệp 2
  Future<List<RegisteredCourse>> fetchRegisteredCourses() async {
    final Uri url = Uri.parse('$baseUrl/registered-courses');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList
            .map((item) => RegisteredCourse.fromJson(item))
            .toList();
      } else {
        _handleApiError(response, 'Lỗi tải danh sách lớp đã đăng ký');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===================================================
  // ⚠️ LEAVE REQUEST MANAGEMENT (TỪ TỆP 1)
  // ===================================================

  Future<List<PendingLeaveRequest>> fetchPendingLeaveRequests() async {
    final Uri url = Uri.parse('$baseUrl/admin/leave-requests/pending');
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        // Chuẩn hóa logic tải danh sách (từ Tệp 2)
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        List<dynamic> dataList = (body is Map<String, dynamic> &&
            body.containsKey('data'))
            ? body['data']
            : (body is List ? body : []);
        return dataList
            .map((item) => PendingLeaveRequest.fromJson(item))
            .toList();
      } else {
        _handleApiError(response, 'Lỗi khi tải danh sách chờ duyệt');
      }
    } catch (e) {
      print("fetchPendingLeaveRequests Error: $e");
      rethrow;
    }
  }

  Future<void> approveLeaveRequest(int requestId) async {
    final Uri url =
    Uri.parse('$baseUrl/admin/leave-requests/$requestId/approve');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'status': 'approved'}),
      );
      if (response.statusCode != 200) {
        _handleApiError(response, 'Lỗi khi duyệt đơn');
      }
    } catch (e) {
      print("approveLeaveRequest Error: $e");
      rethrow;
    }
  }

  Future<void> rejectLeaveRequest(int requestId) async {
    final Uri url =
    Uri.parse('$baseUrl/admin/leave-requests/$requestId/reject');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({'status': 'rejected'}),
      );
      if (response.statusCode != 200) {
        _handleApiError(response, 'Lỗi khi từ chối đơn');
      }
    } catch (e) {
      print("rejectLeaveRequest Error: $e");
      rethrow;
    }
  }

  // ===================================================
  // ⚙️ ERROR HANDLER
  // ===================================================

  /// ---------------------------------------------------
  /// ⚙️ Hàm xử lý lỗi API chung (Phiên bản Tệp 1 - đầy đủ nhất)
  /// ---------------------------------------------------
  Never _handleApiError(http.Response response, String defaultMessage) {
    print(
        "API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
    try {
      // Luôn thử decode body
      final error = jsonDecode(utf8.decode(response.bodyBytes));

      // Xử lý lỗi validation của Laravel (422)
      if (error is Map && error.containsKey('message')) {
        if (error.containsKey('errors')) {
          final errors = error['errors'] as Map;
          // Lấy lỗi đầu tiên từ danh sách lỗi
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw Exception(firstError.first);
          }
        }
        // Nếu không có 'errors' lồng nhau, ném 'message' chính
        throw Exception(error['message']);
      }
      // Nếu không phải định dạng lỗi mong đợi, ném toàn bộ lỗi
      throw Exception(error.toString());
    } catch (e) {
      // Nếu 'e' là lỗi chúng ta vừa ném, ném lại nó
      if (e is Exception) {
        rethrow;
      }
      // Nếu 'e' là lỗi decode JSON (ví dụ: body rỗng hoặc không phải JSON)
      if (e is FormatException) {
        // Ném lỗi mặc định với mã trạng thái
        throw Exception('$defaultMessage (Mã lỗi: ${response.statusCode})');
      }
      // Các lỗi không xác định khác
      rethrow;
    }
  }
}