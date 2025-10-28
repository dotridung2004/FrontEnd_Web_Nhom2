import 'dart:convert'; // For jsonEncode, jsonDecode, utf8
import 'package:flutter/foundation.dart' show kIsWeb; // For checking web platform
import 'package:http/http.dart' as http; // For making HTTP requests

import 'models/course.dart'; // 👈 THÊM DÒNG NÀY
import 'models/class_course.dart';
import 'models/registered_course.dart';
// Import your data models
import 'table/user.dart';
import 'table/home_summary.dart';
import 'models/schedule.dart'; // Make sure this path is correct

class ApiService {
  // --- Singleton Pattern ---
  // Private constructor
  ApiService._internal();
  // Static instance
  static final ApiService _instance = ApiService._internal();
  // Factory constructor to return the static instance
  factory ApiService() {
    return _instance;
  }
  // --- End Singleton Pattern ---

  // --- Base URL Configuration ---
  // Determines the API base URL based on the platform (Web or Mobile Emulator)
  static String get baseUrl {
    if (kIsWeb) {
      // Use localhost for web builds
      return 'http://localhost:8000/api';
    } else {
      // Use 10.0.2.2 for Android Emulator to connect to host's localhost
      return 'http://10.0.2.2:8000/api';
      // Note: For physical devices, replace 10.0.2.2 with your computer's LAN IP.
    }
  }
  // --- End Base URL Configuration ---

  // --- Authentication Token ---
  // Stores the authentication token received after login
  String? _token;
  // --- End Authentication Token ---

  // --- Helper for HTTP Headers ---
  // Creates standard headers for API requests, adding Authorization if needed.
  Map<String, String> _getHeaders({bool needsAuth = true}) {
    final headers = {
      'Content-Type': 'application/json', // We send JSON
      'Accept': 'application/json', // We expect JSON response
    };
    // Add the Bearer token if the request requires authentication and the token exists
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
  /// Attempts to log in the user with email and password.
  /// Returns the User object on success. Stores the auth token internally.
  /// Throws an Exception on failure (network error, invalid credentials, inactive account).
  Future<User> login(String email, String password) async {
    final Uri loginUrl = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        loginUrl,
        headers: _getHeaders(needsAuth: false), // Login doesn't require prior auth
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) { // HTTP 200 OK
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['user']);

        // Store the token if provided by the backend
        if (data['token'] != null) {
          _token = data['token'];
          print("Login successful, Token stored!");
        } else {
          // This indicates a potential backend issue if login succeeds without a token
          print("Warning: Login successful but no token received.");
        }

        // Check if the user account is active before allowing login
        if (user.status == 'active') {
          return user;
        } else {
          throw Exception('❌ Your account has been disabled.');
        }
      } else {
        // Use the error handler for non-200 responses
        _handleApiError(response, 'Login failed');
      }
    } catch (e) {
      // Catch network errors or exceptions thrown by _handleApiError
      print("Login Error: $e");
      if (e is Exception) rethrow; // Keep specific exception messages
      throw Exception('Could not connect to the server.'); // Generic fallback
    }
  }

  /// ---------------------------------------------------
  /// 🏠 Home Screen Data (Admin/Teacher)
  /// ---------------------------------------------------
  /// Fetches summary data for the home screen based on the user ID.
  /// Requires authentication (sends the stored token).
  /// Returns a HomeSummary object.
  /// Throws an Exception on failure.
  Future<HomeSummary> fetchHomeSummary(int userId) async {
    final Uri url = Uri.parse('$baseUrl/users/$userId/home-summary');
    try {
      final response = await http.get(url, headers: _getHeaders()); // Authenticated request
      if (response.statusCode == 200) {
        // Decode using UTF-8 to handle special characters correctly
        return HomeSummary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        _handleApiError(response, 'Error loading home data');
      }
    } catch (e) {
      print("fetchHomeSummary Error: $e");
      rethrow; // Allow the UI (e.g., FutureBuilder) to handle the error
    }
  }

  /// ---------------------------------------------------
  /// 🗓️ Schedule Management - Fetch List
  /// ---------------------------------------------------
  /// Fetches the list of all schedules.
  /// Requires authentication.
  /// Returns a List of Schedule objects.
  /// Throws an Exception on failure.
  Future<List<Schedule>> fetchSchedules() async {
    final Uri url = Uri.parse('$baseUrl/schedules');
    try {
      final response = await http.get(url, headers: _getHeaders()); // Authenticated request
      if (response.statusCode == 200) {
        // Decode response using UTF-8
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> dataList;
        // Check if the response is paginated (Laravel standard) or a direct list
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data']; // Extract list from 'data' key
        } else if (body is List) {
          dataList = body; // Response is already a list
        } else {
          // Unexpected response format
          throw Exception('Invalid data format received');
        }

        // Convert the list of JSON maps into a list of Schedule objects
        return dataList.map((item) => Schedule.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading schedule list');
      }
    } catch (e) {
      print("fetchSchedules Error: $e");
      rethrow; // Allow the UI (e.g., FutureBuilder) to handle the error
    }
  }

// ... (sau hàm fetchSchedules) ...

  /// ---------------------------------------------------
  /// 📚 Course Management - Fetch List
  /// ---------------------------------------------------
  /// Fetches the list of all courses.
  /// Requires authentication.
  /// Returns a List of Course objects.
  /// Throws an Exception on failure.
  Future<List<Course>> fetchCourses() async {
    final Uri url = Uri.parse('$baseUrl/courses'); // 👈 THAY ĐỔI URL
    try {
      final response = await http.get(url, headers: _getHeaders()); // Authenticated request
      if (response.statusCode == 200) {
        // Decode response using UTF-8
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));

        List<dynamic> dataList;
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          dataList = body['data'];
        } else if (body is List) {
          dataList = body;
        } else {
          throw Exception('Invalid data format received');
        }

        // 👇 THAY ĐỔI: Parse sang Course
        return dataList.map((item) => Course.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading course list');
      }
    } catch (e) {
      print("fetchCourses Error: $e");
      rethrow;
    }
  }
  // ... (sau hàm fetchCourses) ...

  /// ---------------------------------------------------
  /// 🏫 Class Course Management - Fetch List
  /// ---------------------------------------------------
  /// Fetches the list of all class-courses.
  /// Requires authentication.
  /// Returns a List of ClassCourse objects.
  /// Throws an Exception on failure.
  Future<List<ClassCourse>> fetchClassCourses() async {
    // 👈 THAY ĐỔI URL
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
          throw Exception('Invalid data format received');
        }

        // 👇 THAY ĐỔI: Parse sang ClassCourse
        return dataList.map((item) => ClassCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading class-course list');
      }
    } catch (e) {
      print("fetchClassCourses Error: $e");
      rethrow;
    }
  }
// ... (Bên dưới hàm fetchClassCourses()) ...

  /// ---------------------------------------------------
  /// 📊 Registered Courses Summary - Fetch List
  /// ---------------------------------------------------
  /// Fetches class-courses with student count.
  Future<List<RegisteredCourse>> fetchRegisteredCourses() async {
    // 👈 URL phải khớp với route bạn tạo trong api.php
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
          throw Exception('Invalid data format received');
        }

        // 👇 Parse sang model RegisteredCourse
        return dataList.map((item) => RegisteredCourse.fromJson(item)).toList();
      } else {
        _handleApiError(response, 'Error loading registered course list');
      }
    } catch (e) {
      print("fetchRegisteredCourses Error: $e");
      rethrow;
    }
  }
  // ===================================================
  // Private Helper Methods
  // ===================================================

  /// ---------------------------------------------------
  /// ⚙️ General API Error Handler
  /// ---------------------------------------------------
  /// Parses standard error responses from the API and throws a formatted Exception.
  /// The return type 'Never' indicates this function *always* throws an exception.
  Never _handleApiError(http.Response response, String defaultMessage) {
    // Log detailed error information for debugging
    print(
        "API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
    try {
      // Attempt to decode the JSON error message from the response body
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      // Throw an exception with the message from the API, or a fallback message
      throw Exception(
          error['message'] ?? '$defaultMessage (Code: ${response.statusCode})');
    } catch (e) {
      // If decoding fails (e.g., non-JSON response) or it's not the expected format
      if (e is FormatException || e is TypeError) {
        // Throw an exception with the default message and status code
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      // If the exception was already parsed successfully (in the 'try' block), rethrow it
      rethrow;
    }
  }
}