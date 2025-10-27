import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart'; // <-- Đã xóa vì không cần
import 'package:flutter/foundation.dart' show kIsWeb;

// Import Models (Chỉ giữ lại User)
import 'table/user.dart'; // <-- Bỏ comment, vì hàm login cần model này

class ApiService {
  // --- 👇 BẮT ĐẦU SỬA LỖI SINGLETON ---
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // --- 👆 KẾT THÚC SỬA LỖI SINGLETON ---

  // --- 👇 BẮT ĐẦU THAY ĐỔI BASE URL ---
  static String get baseUrl {
    if (kIsWeb) {
      // 1. Đang chạy trên WEB (trình duyệt)
      return 'http://localhost:8000/api';
    } else {
      // 2. Đang chạy trên MOBILE (Giả lập Android)
      return 'http://10.0.2.2:8000/api';
    }
  }

  // --- 👆 KẾT THÚC THAY ĐỔI BASE URL ---

  String? _token; // Biến này bây giờ sẽ được chia sẻ toàn ứng dụng

  // --- 👇 SỬA LỖI: THÊM `return headers;` ---
  Map<String, String> _getHeaders({bool needsAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers; // <-- ĐÂY LÀ SỬA LỖI
  }

  /// ---------------------------------------------------
  /// 👤 Xác thực (Authentication)
  /// ---------------------------------------------------

  // --- 👇 THÊM LẠI HÀM LOGIN (TỪ NGỮ CẢNH TRƯỚC) ---
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
          print("Đăng nhập thành công, Token đã được lưu!");
        } else {
          print("Cảnh báo: Đăng nhập thành công nhưng không nhận được token.");
        }

        // Sửa logic: Chỉ kiểm tra status, role sẽ được kiểm tra ở Flutter
        if (user.status == 'active') {
          return user;
        } else {
          throw Exception('❌ Tài khoản của bạn đã bị vô hiệu hóa.');
        }
      } else {
        // 👇 *** SỬA LỖI LINTER ***
        // Không cần 'return' vì _handleApiError trả về 'Never'
        _handleApiError(response, 'Đăng nhập thất bại');
      }
    } catch (e) {
      print("Login Error: $e");
      if (e is Exception) rethrow;
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  // --- (Tất cả các hàm API khác đã bị xóa) ---

  /// ---------------------------------------------------
  /// ⚙️ Hàm xử lý lỗi API chung (Private Helper)
  /// ---------------------------------------------------
  Never _handleApiError(http.Response response, String defaultMessage) {
    print(
        "API Error (${response.request?.url}): ${response.statusCode} - ${response.body}");
    try {
      // Thử decode bằng utf8 trước
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          error['message'] ?? '$defaultMessage (Code: ${response.statusCode})');
    } catch (e) {
      // Nếu decode utf8 thất bại (ví dụ: body không phải JSON), dùng message mặc định
      if (e is FormatException) {
        throw Exception('$defaultMessage (Code: ${response.statusCode})');
      }
      // Ném lại lỗi đã được parse (từ try)
      rethrow;
    }
  }
}