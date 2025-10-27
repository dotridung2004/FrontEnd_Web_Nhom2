import 'package:flutter/material.dart';
import 'home_screen.dart'; // <-- Trang chủ để điều hướng đến

// (Giả sử LoginScreen ở trong 'lib/screens/')
import '../api_service.dart'; // Nhập ApiService
import '../table/user.dart';   // Nhập Model User

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Biến để quản lý việc ẩn/hiện mật khẩu
  bool _isPasswordHidden = true;

  // 1. Service và Controllers
  final ApiService _apiService = ApiService(); // Lấy thực thể Singleton
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 2. Biến trạng thái
  bool _isLoading = false;
  String _errorMessage = '';

  // Màu sắc chủ đạo từ hình ảnh
  final Color tluLogoBlue = Color(0xFF005A9C);
  final Color leftPanelBg = Color(0xFF5C9DFF);
  final Color loginButtonBlue = Color(0xFF4295F7);
  final Color forgotPasswordRed = Color(0xFFE53935);

  /// Xử lý logic khi nhấn nút Đăng nhập
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Vui lòng nhập đầy đủ tài khoản và mật khẩu.");
      }

      final User user = await _apiService.login(email, password);

      if (user.role == 'training_office') {
        if (mounted) {
          // --- 👇 THAY ĐỔI QUAN TRỌNG ---
          // Gửi thông tin 'user' sang HomeScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
          );
          // --- 👆 KẾT THÚC THAY ĐỔI ---
        }
      } else {
        throw Exception(
            'Tài khoản không có quyền truy cập (Chỉ dành cho Phòng đào tạo).');
      }

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F8),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout();
            }
          },
        ),
      ),
    );
  }

  /// Layout cho màn hình rộng (Desktop/Tablet)
  Widget _buildWideLayout() {
    return Container(
      width: 900,
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Row(
          children: [
            Expanded(child: _buildLeftPanel()),
            Expanded(child: _buildRightPanel(isMobile: false)),
          ],
        ),
      ),
    );
  }

  /// Layout cho màn hình hẹp (Điện thoại)
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.all(24.0),
        padding: EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _buildRightPanel(isMobile: true),
      ),
    );
  }

  /// Widget cho cột bên trái (thông tin TLU và hình ảnh)
  Widget _buildLeftPanel() {
    return Container(
      color: leftPanelBg,
      padding: EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: tluLogoBlue,
                child: Text(
                  "TLU",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26),
                ),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thuy Loi",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "University",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 24),
          Text(
            "Teaching Schedule",
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.w300),
          ),
          Spacer(),
          Center(
            child: Image.asset(
              'assets/images/login_graphic.png',
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 80, color: Colors.white.withOpacity(0.8)),
                      SizedBox(height: 10),
                      Text(
                        "Không tìm thấy ảnh tại:\n'assets/images/login_graphic.png'",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white70, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }


  /// Widget cho cột bên phải (Form đăng nhập)
  Widget _buildRightPanel({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 48.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: tluLogoBlue,
                child: Text(
                  "TLU",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
          Text(
            "Đăng nhập",
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 32),
          Text(
            "Tài khoản",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _emailController, // Gắn controller
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "Nhập tài khoản (email)",
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: loginButtonBlue, width: 2.0),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            "Mật khẩu",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _passwordController, // Gắn controller
            obscureText: _isPasswordHidden, // Ẩn mật khẩu
            decoration: InputDecoration(
              hintText: "Nhập mật khẩu",
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: loginButtonBlue, width: 2.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Xử lý sự kiện quên mật khẩu
              },
              child: Text(
                "Quên mật khẩu",
                style: TextStyle(
                    color: forgotPasswordRed, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 24),
          if (_errorMessage.isNotEmpty) ...[
            Container(
              width: double.infinity,
              child: Text(
                _errorMessage,
                style: TextStyle(color: forgotPasswordRed, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : Text(
                "Đăng nhập",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: loginButtonBlue, // Màu nút
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 5,
                shadowColor: loginButtonBlue.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}