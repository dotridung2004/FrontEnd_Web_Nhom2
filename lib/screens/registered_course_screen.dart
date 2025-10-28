// lib/screens/registered_course_screen.dart

import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/registered_course.dart'; // 👈 1. Import model mới

class RegisteredCourseScreen extends StatefulWidget { // 👈 2. Đổi tên Class
  const RegisteredCourseScreen({Key? key}) : super(key: key);

  @override
  _RegisteredCourseScreenState createState() => _RegisteredCourseScreenState(); // 👈 2. Đổi tên Class
}

class _RegisteredCourseScreenState extends State<RegisteredCourseScreen> { // 👈 2. Đổi tên Class
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State
  late Future<List<RegisteredCourse>> _registeredCoursesFuture; // 👈 3. Đổi Future
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _registeredCoursesFuture = _apiService.fetchRegisteredCourses(); // 👈 4. Gọi API mới
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RegisteredCourse>>( // 👈 5. Đổi FutureBuilder
      future: _registeredCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi khi tải dữ liệu: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildContent(context, []); // Hiển thị bảng rỗng
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  /// Widget build nội dung chính
  Widget _buildContent(BuildContext context, List<RegisteredCourse> courses) { // 👈 6. Đổi kiểu List
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header, Nút, Tìm kiếm
          Wrap(
            spacing: 24.0, runSpacing: 16.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Text(
                        "Đăng ký học phần", // 👈 7. Đổi Tiêu đề
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      );
                    }
                    return SizedBox.shrink();
                  }
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút "Đăng ký"
                  ElevatedButton.icon(
                    onPressed: () { /* TODO: Xử lý Đăng ký */ },
                    icon: Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text("Đăng ký", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // 👈 8. Đổi tên Nút
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tluBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Thanh Tìm kiếm (giữ nguyên)
                  Container(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onChanged: (value) { /* TODO: Xử lý Tìm kiếm */ },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Bảng Dữ liệu
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(tluBlue),
                    headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    // 👈 9. Đổi Cột
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Mã học phần')),
                      DataColumn(label: Text('Tên học phần')),
                      DataColumn(label: Text('Giảng viên')),
                      DataColumn(label: Text('Học kì')),
                      DataColumn(label: Text('Tổng số SV')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: List.generate(
                      courses.length,
                          (index) => _buildDataRow(index + 1, courses[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Helper build một hàng
  DataRow _buildDataRow(int stt, RegisteredCourse course) { // 👈 10. Đổi model
    return DataRow(
      cells: [
        // 👈 11. Đổi các ô
        DataCell(Text(stt.toString())),
        DataCell(Text(course.classCode)),
        DataCell(Text(course.courseName)),
        DataCell(Text(course.teacherName)),
        DataCell(Text(course.semester)),
        DataCell(Text(course.totalStudents.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: Icon(Icons.info_outline, color: iconView), onPressed: () { /* View */ }, tooltip: "Xem"),
              IconButton(icon: Icon(Icons.edit_outlined, color: iconEdit), onPressed: () { /* Edit */ }, tooltip: "Sửa"),
              IconButton(icon: Icon(Icons.delete_outline, color: iconDelete), onPressed: () { /* Delete */ }, tooltip: "Xóa"),
            ],
          ),
        ),
      ],
    );
  }
}