import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Biến để quản lý việc ẩn/hiện mật khẩu
  bool _isPasswordHidden = true;

  // Màu sắc chủ đạo từ hình ảnh
  final Color tluLogoBlue = Color(0xFF005A9C); // Màu xanh đậm của logo TLU
  final Color leftPanelBg = Color(0xFF5C9DFF); // Màu xanh nhạt bên trái
  final Color loginButtonBlue = Color(0xFF4295F7); // Màu nút đăng nhập
  final Color forgotPasswordRed = Color(0xFFE53935); // Màu đỏ "Quên mật khẩu"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền xám nhạt cho toàn bộ màn hình
      backgroundColor: Color(0xFFF0F4F8),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Kiểm tra chiều rộng màn hình để quyết định layout
            if (constraints.maxWidth > 800) {
              // Layout cho màn hình rộng (Desktop, Tablet)
              return _buildWideLayout();
            } else {
              // Layout cho màn hình hẹp (Điện thoại)
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
      width: 900, // Chiều rộng cố định của card
      height: 600, // Chiều cao cố định của card
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
      // ClipRRect để đảm bảo các con bên trong cũng bị cắt theo góc bo
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Row(
          children: [
            // Cột bên trái (màu xanh)
            Expanded(child: _buildLeftPanel()),
            // Cột bên phải (form đăng nhập)
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
        // Chỉ hiển thị form đăng nhập, với logo ở trên
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
                backgroundColor: tluLogoBlue, // Màu logo TLU từ ảnh
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
          // Tên ứng dụng
          Text(
            "Teaching Schedule",
            style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.w300),
          ),
          Spacer(),
          // --- HÌNH ẢNH ---
          // Đã thay thế placeholder bằng hình ảnh thật từ assets
          // ĐẢM BẢO BẠN ĐÃ thêm ảnh vào 'assets/images/login_graphic.png'
          // và khai báo trong pubspec.yaml
          Center(
            child: Image.asset(
              'assets/images/login_graphic.png', // <-- Đường dẫn đến ảnh của bạn
              height: 250, // Điều chỉnh kích thước nếu cần
              errorBuilder: (context, error, stackTrace) {
                // Hiển thị thông báo lỗi nếu không tìm thấy ảnh
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
                        "Không tìm thấy ảnh tại:\n'assets/images/login_graphic.png'\n\nVui lòng kiểm tra lại pubspec.yaml",
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
          // Hiển thị logo TLU ở trên nếu là layout mobile
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

          // Tiêu đề
          Text(
            "Đăng nhập",
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          SizedBox(height: 32),

          // Form Tài khoản
          Text(
            "Tài khoản",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: "Nhập tài khoản",
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

          // Form Mật khẩu
          Text(
            "Mật khẩu",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          SizedBox(height: 8),
          TextFormField(
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
              // Icon để ẩn/hiện mật khẩu
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  // Cập nhật trạng thái để vẽ lại UI
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 16),

          // Link Quên mật khẩu
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

          // Nút Đăng nhập
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Xử lý sự kiện đăng nhập
              },
              child: Text(
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