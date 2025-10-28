import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/class_course.dart'; // Đảm bảo đã tạo model này

class LopHocPhanScreen extends StatefulWidget {
  const LopHocPhanScreen({Key? key}) : super(key: key);

  @override
  _LopHocPhanScreenState createState() => _LopHocPhanScreenState();
}

class _LopHocPhanScreenState extends State<LopHocPhanScreen> {
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State cho FutureBuilder
  late Future<List<ClassCourse>> _classCoursesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi vào trang
    _classCoursesFuture = _apiService.fetchClassCourses();
  }

  // Hàm build UI chính
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClassCourse>>(
      future: _classCoursesFuture,
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
  Widget _buildContent(BuildContext context, List<ClassCourse> classCourses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nút Thêm và Tìm kiếm (Đã sửa layout)
          // 👇 === THAY ĐỔI TỪ WRAP THÀNH ROW === 👇
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy 2 item ra 2 bên
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nút "Thêm lớp học phần" (BÊN TRÁI)
              ElevatedButton.icon(
                onPressed: () { /* TODO: Xử lý Thêm */ },
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm lớp học phần", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),

              // Thanh "Tìm kiếm" (BÊN PHẢI)
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
          // 👆 === KẾT THÚC THAY ĐỔI === 👆
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
                      DataColumn(label: Text('Tên lớp học phần')),
                      DataColumn(label: Text('Giảng viên phụ trách')),
                      DataColumn(label: Text('Khoa')),
                      DataColumn(label: Text('Học phần')),
                      DataColumn(label: Text('Học kỳ')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: List.generate(
                      classCourses.length,
                          (index) => _buildDataRow(index + 1, classCourses[index]),
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
  DataRow _buildDataRow(int stt, ClassCourse classCourse) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(classCourse.name)),
        DataCell(Text(classCourse.teacherName)),
        DataCell(Text(classCourse.departmentName)),
        DataCell(Text(classCourse.courseName)),
        DataCell(Text(classCourse.semester)),
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

