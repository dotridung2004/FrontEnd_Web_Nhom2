import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import để Đăng xuất
import 'khoa_screen.dart';
import 'dashboard_content.dart';
import '../table/user.dart'; // 👈 THÊM IMPORT NÀY

class HomeScreen extends StatefulWidget {
  // 👇 THÊM DÒNG NÀY: Nhận User từ LoginScreen
  final User user;

  // 👇 SỬA DÒNG NÀY: Thêm 'required this.user'
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Màu sắc
  final Color tluBlue = Color(0xFF005A9C);
  final Color tluLightBlue = Color(0xFF0D6EBA);
  final Color appBarBg = Colors.white;
  final Color screenBg = Color(0xFFF0F4F8);
  final Color logoutRed = Color(0xFFD32F2F);

  // --- 👇 BẮT ĐẦU: Quản lý State (Trạng thái) ---
  late Widget _selectedContent; // Sửa: Dùng `late`
  String _selectedTitle = "Trang chủ";
  String _selectedMenuKey = "TRANG_CHU";

  // 👇 THÊM HÀM `initState`
  @override
  void initState() {
    super.initState();
    // Khởi tạo trang mặc định và TRUYỀN USER
    _selectedContent = DashboardContent(user: widget.user);
  }

  // Hàm để thay đổi nội dung khi nhấn menu
  void _onMenuItemSelected(String key, String title, Widget content) {
    setState(() {
      _selectedMenuKey = key;
      _selectedTitle = title;
      _selectedContent = content;
    });

    final scaffold = Scaffold.of(context);
    if (scaffold.hasDrawer && scaffold.isDrawerOpen) {
      Navigator.pop(context);
    }
  }
  // --- 👆 KẾT THÚC: Quản lý State ---

  // 👇 THÊM HÀM HELPER ĐỂ FORMAT VAI TRÒ
  String _formatRole(String role) {
    switch (role) {
      case 'training_office':
        return 'Phòng Đào tạo';
      case 'teacher':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      default:
        return 'Quản trị viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSideMenu(),
        Expanded(
          child: Scaffold(
            backgroundColor: screenBg,
            appBar: _buildTopAppBar(isMobile: false, title: _selectedTitle),
            body: _selectedContent, // Nội dung động
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: screenBg,
      appBar: _buildTopAppBar(isMobile: true, title: _selectedTitle),
      drawer: _buildSideMenu(),
      body: _selectedContent, // Nội dung động
    );
  }

  // --- WIDGETS CHO CÁC THÀNH PHẦN ---

  Widget _buildSideMenu() {
    return Container(
      width: 250,
      color: tluBlue,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header TLU
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

          _buildMenuItem(
            "TRANG CHỦ",
            "TRANG_CHU",
            onTap: () => _onMenuItemSelected(
              "TRANG_CHU",
              "Trang chủ",
              DashboardContent(user: widget.user), // 👈 TRUYỀN USER
            ),
          ),

          _buildExpansionMenuItem(
            "DANH MỤC",
            "DANH_MUC",
            children: [
              _buildMenuItem(
                "Khoa",
                "KHOA",
                onTap: () => _onMenuItemSelected(
                  "KHOA",
                  "Khoa",
                  const KhoaScreen(), // 👈 Trang Khoa
                ),
              ),
              _buildMenuItem("Bộ môn", "BO_MON", onTap: () { /* TODO */ }),
              _buildMenuItem("Ngành học", "NGANH_HOC", onTap: () { /* TODO */ }),
              _buildMenuItem("Phòng học", "PHONG_HOC", onTap: () { /* TODO */ }),
            ],
          ),

          _buildExpansionMenuItem(
              "HỌC PHẦN",
              "HOC_PHAN",
              children: [
                _buildMenuItem("Học phần", "HP", onTap: () { /* TODO */ }),
                _buildMenuItem("Lớp học phần", "LHP", onTap: () { /* TODO */ }),
                _buildMenuItem("Học phần đã đăng ký", "HP_DK", onTap: () { /* TODO */ }),
              ]
          ),

          _buildMenuItem("GIẢNG VIÊN", "GIANG_VIEN", onTap: () { /* TODO */ }),
          _buildMenuItem("LỊCH HỌC", "LICH_HOC", onTap: () { /* TODO */ }),
          _buildMenuItem("THỐNG KÊ - BÁO CÁO", "THONG_KE", onTap: () { /* TODO */ }),
          _buildMenuDivider(),
          _buildMenuItem("TÀI KHOẢN", "TAI_KHOAN", onTap: () { /* TODO */ }),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar({required bool isMobile, required String title}) {
    // 👈 Lấy ký tự đầu của tên
    final String firstLetter = widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "A";

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: isMobile
          ? Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.black87),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      )
          : null,
      title: (isMobile || title != "Trang chủ")
          ? Text(
          title,
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold
          )
      )
          : null,

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
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
        VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade300),

        // --- 👇 THAY ĐỔI THÔNG TIN USER ĐỘNG ---
        Center(
          child: CircleAvatar(
            radius: 16,
            backgroundColor: tluBlue,
            child: Text(firstLetter, style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: 8),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, // 👈 Tên động
                  style: TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.bold)),
              Text(_formatRole(widget.user.role), // 👈 Vai trò động
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        // --- 👆 KẾT THÚC THAY ĐỔI ---

        SizedBox(width: 16),
        // Nút Đăng xuất
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
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

  // --- Helper Widgets cho Menu ---

  Widget _buildMenuItem(String title, String key, {VoidCallback? onTap}) {
    final bool isSelected = (_selectedMenuKey == key);
    return Container(
      color: isSelected ? tluLightBlue : Colors.transparent,
      child: ListTile(
        title: Text(title,
            style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildExpansionMenuItem(String title, String key,
      {List<Widget> children = const []}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        title: Text(title, style: TextStyle(color: Colors.white)),
        children: children
            .map((child) => Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: child,
        ))
            .toList(),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Divider(color: Colors.white.withOpacity(0.2), height: 1),
    );
  }
}