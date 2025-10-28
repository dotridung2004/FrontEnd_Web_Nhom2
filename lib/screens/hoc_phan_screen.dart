import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/course.dart'; // Đảm bảo đã tạo model này

class HocPhanScreen extends StatefulWidget {
  const HocPhanScreen({Key? key}) : super(key: key);

  @override
  _HocPhanScreenState createState() => _HocPhanScreenState();
}

class _HocPhanScreenState extends State<HocPhanScreen> {
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State cho FutureBuilder
  late Future<List<Course>> _coursesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi vào trang
    _coursesFuture = _apiService.fetchCourses();
  }

  // Hàm build UI chính
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        // 1. Trạng thái Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // 2. Trạng thái Lỗi
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải dữ liệu: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // 3. Trạng thái Không có dữ liệu
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Vẫn hiển thị UI (với bảng rỗng) để người dùng có thể "Thêm"
          return _buildContent(context, []);
        }

        // 4. Trạng thái Thành công
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  /// Widget chứa nội dung (Tiêu đề, Nút, Bảng)
  Widget _buildContent(BuildContext context, List<Course> courses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Thanh Tiêu đề, Nút Thêm, và Tìm kiếm
          Wrap(
            spacing: 24.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Tiêu đề "Học phần" (sẽ ẩn trên mobile)
              LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Text(
                        "Học phần",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      );
                    }
                    return SizedBox.shrink(); // Ẩn trên màn hình hẹp
                  }
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút "Thêm học phần"
                  ElevatedButton.icon(
                    onPressed: () { /* TODO: Xử lý Thêm */ },
                    icon: Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text("Thêm học phần", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tluBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Thanh "Tìm kiếm"
                  Container(
                    width: 300,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12.0),
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
                    headingTextStyle: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    // Tiêu đề cột khớp với ảnh
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Mã học phần')),
                      DataColumn(label: Text('Tên học phần')),
                      DataColumn(label: Text('Số tín chỉ')),
                      DataColumn(label: Text('Khoa phụ trách')),
                      DataColumn(label: Text('Loại học phần')),
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

  /// Helper để tạo một hàng dữ liệu (DataRow)
  DataRow _buildDataRow(int stt, Course course) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(course.code)),
        DataCell(Text(course.name)),
        // Thêm " Tín chỉ" để khớp với ảnh
        DataCell(Text("${course.credits.toString()} Tín chỉ")),
        DataCell(Text(course.departmentName)),
        DataCell(Text(course.type)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconView),
                onPressed: () { /* TODO: Xử lý View */ },
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEdit),
                onPressed: () { /* TODO: Xử lý Edit */ },
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDelete),
                onPressed: () { /* TODO: Xử lý Delete */ },
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }
}