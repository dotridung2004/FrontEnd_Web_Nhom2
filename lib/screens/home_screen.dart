import 'package:flutter/material.dart';
import 'login_screen.dart'; // <-- 1. THÊM IMPORT NÀY

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Màu sắc chủ đạo từ hình ảnh
  final Color tluBlue = Color(0xFF005A9C);
  final Color tluLightBlue = Color(0xFF0D6EBA); // Màu xanh nhạt hơn cho menu
  final Color appBarBg = Colors.white;
  final Color screenBg = Color(0xFFF0F4F8);
  final Color logoutRed = Color(0xFFD32F2F); // Gần giống màu nút "Đăng xuất"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Layout màn hình rộng (Desktop)
            return _buildWideLayout();
          } else {
            // Layout màn hình hẹp (Điện thoại)
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  // --- WIDGETS CHO LAYOUT CHÍNH ---

  /// Layout cho màn hình rộng (Desktop/Tablet)
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Thanh menu bên trái
        _buildSideMenu(),
        // Nội dung chính
        Expanded(
          child: Scaffold(
            backgroundColor: screenBg,
            appBar: _buildTopAppBar(isMobile: false),
            body: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  /// Layout cho màn hình hẹp (Điện thoại)
  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: screenBg,
      appBar: _buildTopAppBar(isMobile: true),
      drawer: _buildSideMenu(), // Menu bên sẽ là một Drawer
      body: _buildMainContent(),
    );
  }

  // --- WIDGETS CHO CÁC THÀNH PHẦN ---

  /// Xây dựng Thanh menu bên trái (Side Menu)
  Widget _buildSideMenu() {
    return Container(
      width: 250, // Chiều rộng của thanh menu
      color: tluBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header của menu
          Container(
            padding: EdgeInsets.all(20.0).copyWith(top: 40.0, bottom: 30.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    "TLU",
                    style: TextStyle(
                        color: tluBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thuy Loi",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text("University",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                )
              ],
            ),
          ),
          _buildMenuDivider(),
          _buildMenuItem("TRANG CHỦ", isSelected: true),
          _buildExpansionMenuItem("DANH MỤC",
              children: ["Khoa", "Bộ môn", "Ngành học", "Phòng học"]),
          _buildExpansionMenuItem("HỌC PHẦN",
              children: ["Học phần", "Lớp học phần", "Học phần đã đăng ký"]),
          _buildMenuItem("GIẢNG VIÊN"),
          _buildMenuItem("LỊCH HỌC"),
          _buildMenuItem("THỐNG KÊ - BÁO CÁO"),
          _buildMenuDivider(),
          _buildMenuItem("TÀI KHOẢN"),
        ],
      ),
    );
  }

  /// Xây dựng Thanh ứng dụng trên cùng (App Bar)
  PreferredSizeWidget _buildTopAppBar({required bool isMobile}) {
    return AppBar(
      backgroundColor: appBarBg,
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      // Hiển thị nút hamburger (☰) trên mobile
      leading: isMobile
          ? Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      )
          : null,
      // Tiêu đề
      title: isMobile
          ? Text("Trang chủ",
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold))
          : null, // Màn hình rộng không cần title ở đây
      actions: [
        // Nút chuông thông báo
        IconButton(
          onPressed: () {},
          icon: Stack(
            children: [
              Icon(Icons.notifications_outlined, color: Colors.black54),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                  child: Text(
                    '3', // Số thông báo
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
        VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade300),
        // Thông tin admin
        Center(
          child: CircleAvatar(
            radius: 16,
            backgroundColor: tluBlue,
            child: Text("D", style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: 8),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Admin",
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
              Text("Quản trị viên",
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        SizedBox(width: 16),
        // Nút đăng xuất
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: ElevatedButton(
            // --- 👇 2. THAY ĐỔI LOGIC TRONG NÚT NÀY ---
            onPressed: () {
              // Xử lý đăng xuất
              // Quay lại màn hình Login và xóa tất cả các màn hình trước đó
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            // --- 👆 KẾT THÚC THAY ĐỔI ---
            style: ElevatedButton.styleFrom(
              backgroundColor: logoutRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text("Đăng xuất"),
          ),
        ),
      ],
    );
  }

  /// Xây dựng Nội dung chính của trang
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề "Trang chủ" (chỉ hiển thị trên màn hình rộng)
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Text(
                "Trang chủ",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              );
            }
            return SizedBox.shrink(); // Ẩn trên mobile
          }),
          SizedBox(height: 24),
          // Hàng 3 thẻ thống kê
          Wrap(
            spacing: 24.0, // Khoảng cách ngang
            runSpacing: 24.0, // Khoảng cách dọc (khi xuống hàng)
            children: [
              _buildStatCard(
                  "Tổng số người dùng", "18", Icons.person_outline, Colors.blue),
              _buildStatCard(
                  "Tổng số giảng viên", "3", Icons.group_outlined, Colors.green),
              _buildStatCard(
                  "Tổng số lớp học", "4", Icons.book_outlined, Colors.orange),
            ],
          ),
          SizedBox(height: 32),
          // Lịch dạy hôm nay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Lịch dạy hôm nay",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Text(
                "Thứ 2, 13/10/2025",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Hàng 2 thẻ lịch dạy
          Wrap(
            spacing: 24.0,
            runSpacing: 24.0,
            children: [
              _buildScheduleCard(
                "Kiều Tuấn Dũng",
                "Phát triển ứng dụng di động",
                "64KTPM4",
                "7:00 - 9:40",
                "315-A2",
                "Phát triển ứng dụng di động",
                "64KTPM5",
                "9:45 - 12:25",
                "319-A2",
              ),
              _buildScheduleCard(
                "Tạ Chí Hiếu",
                "Nền tảng web",
                "64KTPM4",
                "9:45 - 12:25",
                "315-A2",
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGETS CON (HELPER) ---

  /// Widget cho một mục menu
  Widget _buildMenuItem(String title, {bool isSelected = false}) {
    return Container(
      color: isSelected ? tluLightBlue : Colors.transparent,
      child: ListTile(
        title: Text(title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () {},
        dense: true,
      ),
    );
  }

  /// Widget cho một mục menu có thể mở rộng
  Widget _buildExpansionMenuItem(String title,
      {List<String> children = const []}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        title: Text(title, style: TextStyle(color: Colors.white)),
        children: children
            .map((child) => Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: _buildMenuItem(child),
        ))
            .toList(),
      ),
    );
  }

  /// Đường kẻ phân cách trong menu
  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
    );
  }

  /// Widget cho thẻ thống kê (Tổng số...)
  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      width: 280, // Chiều rộng cố định cho các thẻ
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(count,
                  style: TextStyle(
                      fontSize: 32,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, size: 36, color: color.withOpacity(0.8)),
        ],
      ),
    );
  }

  /// Widget cho thẻ lịch dạy
  Widget _buildScheduleCard(
      String teacher,
      String course1,
      String class1,
      String time1,
      String room1, [
        // Tham số tùy chọn cho lịch thứ 2
        String? course2,
        String? class2,
        String? time2,
        String? room2,
      ]) {
    return Container(
      width: 430, // Chiều rộng thẻ
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên giảng viên
          Text(teacher,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tluBlue)),
          Divider(height: 24, color: Colors.grey.shade200),
          // Lịch 1
          _buildScheduleRow(course1, class1, time1, room1),
          // Nếu có lịch 2, hiển thị nó
          if (course2 != null) ...[
            SizedBox(height: 16),
            _buildScheduleRow(course2, class2!, time2!, room2!),
          ],
        ],
      ),
    );
  }

  /// Widget cho một hàng thông tin lịch dạy
  Widget _buildScheduleRow(
      String course, String className, String time, String room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(course,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(className,
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text(time, style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text(room,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}