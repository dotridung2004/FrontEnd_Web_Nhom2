// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import để Đăng xuất
import '../screens/khoa_screen.dart';
import '../screens/dashboard_content.dart';
import '../table/user.dart';
import '../screens/lich_hoc_screen.dart';
import '../screens/giang_vien_screen.dart';
import '../screens/tai_khoan_screen.dart';
import '../screens/duyet_yeu_cau_screen.dart'; // 👈 THÊM 1: Import màn hình mới

class HomeScreen extends StatefulWidget {
  final User user;
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

  int _selectedIndex = 0;
  String _selectedTitle = "Trang chủ";
  String _selectedMenuKey = "TRANG_CHU";

  final double _menuFontSize = 15.0;
  late final List<Widget> _mainScreens;

  @override
  void initState() {
    super.initState();
    // 👈 THÊM 2: Thêm màn hình mới vào danh sách
    _mainScreens = [
      DashboardContent(user: widget.user), // Index 0
      const KhoaScreen(),                   // Index 1
      const GiangVienScreen(),              // Index 2
      const LichHocScreen(),                // Index 3
      const DuyetYeuCauScreen(),            // Index 4  <- MÀN HÌNH MỚI
      // TODO: Thêm màn hình Thống kê
      // const ThongKeScreen(),             // Index 5
      const TaiKhoanScreen(),               // Index 6  <- CẬP NHẬT INDEX
    ];
  }

  void _onMenuItemSelected(String key, String title, int index) {
    if (index < 0 || index >= _mainScreens.length) return;
    setState(() {
      _selectedMenuKey = key;
      _selectedTitle = title;
      _selectedIndex = index;
    });
    // Tự động đóng drawer trên mobile sau khi chọn
    if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'training_office': return 'Phòng Đào tạo';
      case 'teacher': return 'Giảng viên';
      case 'student': return 'Sinh viên';
      default: return 'Quản trị viên';
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
            body: IndexedStack(
              index: _selectedIndex,
              children: _mainScreens,
            ),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _mainScreens,
      ),
    );
  }

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
                  child: Text("TLU", style: TextStyle(color: tluBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thuy Loi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("University", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                )
              ],
            ),
          ),
          _buildMenuDivider(),

          // 👈 THÊM 3: Thêm mục menu mới và cập nhật index
          _buildMenuItem(
            "TRANG CHỦ", "TRANG_CHU",
            onTap: () => _onMenuItemSelected("TRANG_CHU", "Trang chủ", 0),
          ),
          _buildExpansionMenuItem("DANH MỤC", "DANH_MUC", children: [
            _buildMenuItem("Khoa", "KHOA", onTap: () => _onMenuItemSelected("KHOA", "Khoa", 1)),
            _buildMenuItem("Bộ môn", "BO_MON", onTap: () { /* TODO: Cập nhật index khi có màn hình */ }),
            _buildMenuItem("Ngành học", "NGANH_HOC", onTap: () { /* TODO: Cập nhật index khi có màn hình */ }),
            _buildMenuItem("Phòng học", "PHONG_HOC", onTap: () { /* TODO: Cập nhật index khi có màn hình */ }),
          ]),
          _buildExpansionMenuItem("HỌC PHẦN", "HOC_PHAN", children: [
            _buildMenuItem("Học phần", "HP", onTap: () { /* TODO */ }),
            _buildMenuItem("Lớp học phần", "LHP", onTap: () { /* TODO */ }),
            _buildMenuItem("Học phần đã đăng ký", "HP_DK", onTap: () { /* TODO */ }),
          ]),

          _buildMenuItem(
            "GIẢNG VIÊN",
            "GIANG_VIEN",
            onTap: () => _onMenuItemSelected("GIANG_VIEN", "Giảng viên", 2),
          ),

          _buildMenuItem(
            "LỊCH HỌC",
            "LICH_HOC",
            onTap: () => _onMenuItemSelected("LICH_HOC", "Lịch học", 3),
          ),

          // --- MỤC MỚI ---
          _buildMenuItem(
            "DUYỆT YÊU CẦU",
            "DUYET_YEU_CAU",
            onTap: () => _onMenuItemSelected(
              "DUYET_YEU_CAU",
              "Duyệt yêu cầu nghỉ/bù",
              4, // Index 4 (mới)
            ),
          ),
          // --- KẾT THÚC MỤC MỚI ---

          _buildMenuItem("THỐNG KÊ - BÁO CÁO", "THONG_KE", onTap: () { /* TODO: Cập nhật index khi có màn hình */ }),
          _buildMenuDivider(),

          _buildMenuItem(
            "TÀI KHOẢN",
            "TAI_KHOAN",
            onTap: () => _onMenuItemSelected(
              "TAI_KHOAN",
              "Quản lý Tài khoản",
              5, // <<< CẬP NHẬT INDEX (từ 4 lên 5)
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar({required bool isMobile, required String title}) {
    final String firstLetter = widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : "A";
    return AppBar(
      backgroundColor: appBarBg,
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: isMobile
          ? Builder(builder: (context) => IconButton(icon: Icon(Icons.menu, color: Colors.black87), onPressed: () => Scaffold.of(context).openDrawer()))
          : null,
      title: (isMobile || title != "Trang chủ")
          ? Text(title, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))
          : null,
      actions: [
        IconButton(
          onPressed: () {},
          icon: Stack(children: [
            Icon(Icons.notifications_outlined, color: Colors.black54),
            Positioned(
                right: 0,
                top: 0,
                child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text('3', style: TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center)
                )
            )
          ]),
        ),
        VerticalDivider(indent: 12, endIndent: 12, color: Colors.grey.shade300),
        Center(child: CircleAvatar(radius: 16, backgroundColor: tluBlue, child: Text(firstLetter, style: TextStyle(color: Colors.white)))),
        SizedBox(width: 8),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.name, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              Text(_formatRole(widget.user.role), style: TextStyle(color: Colors.black54, fontSize: 12))
            ],
          ),
        ),
        SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen())),
              style: ElevatedButton.styleFrom(
                  backgroundColor: logoutRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
              ),
              child: Text("Đăng xuất")
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets cho Menu (Giữ nguyên) ---
  Widget _buildMenuItem(String title, String key, {VoidCallback? onTap}) {
    final bool isSelected = (_selectedMenuKey == key);
    return Container(
      color: isSelected ? tluLightBlue : Colors.transparent,
      child: ListTile(
        title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: _menuFontSize,
            )
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildExpansionMenuItem(String title, String key, {List<Widget> children = const []}) {
    // Logic kiểm tra con được chọn (nếu cần)
    final bool isChildSelected = children.any((child) {
      // Logic này cần được triển khai đúng nếu bạn muốn menu tự động mở
      return false;
    });

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        title: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: _menuFontSize,
            )
        ),
        children: children.map((child) => Padding(padding: const EdgeInsets.only(left: 16.0), child: child)).toList(),
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