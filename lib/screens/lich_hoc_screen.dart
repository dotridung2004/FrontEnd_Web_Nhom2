import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/schedule.dart'; // Import model

class LichHocScreen extends StatefulWidget {
  const LichHocScreen({Key? key}) : super(key: key);

  @override
  _LichHocScreenState createState() => _LichHocScreenState();
}

class _LichHocScreenState extends State<LichHocScreen> {
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State cho FutureBuilder
  late Future<List<Schedule>> _schedulesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Gọi API ngay khi vào trang
    _schedulesFuture = _apiService.fetchSchedules();
  }

  // Hàm build UI chính
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Schedule>>(
      future: _schedulesFuture,
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
          return _buildContent(context, []); // Vẫn hiển thị UI nhưng bảng rỗng
        }

        // 4. Trạng thái Thành công
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  /// Widget chứa nội dung (Tiêu đề, Nút, Bảng)
  Widget _buildContent(BuildContext context, List<Schedule> schedules) {
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
              Text(
                "Lịch học",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Thêm
                  ElevatedButton.icon(
                    onPressed: () { /* TODO: Xử lý Thêm */ },
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Thêm", style: TextStyle(color: Colors.white)),
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
                  // Thanh Tìm kiếm
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
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Tên giảng viên')),
                      DataColumn(label: Text('Lớp học phần')),
                      DataColumn(label: Text('Học phần')),
                      DataColumn(label: Text('Học kỳ')),
                      DataColumn(label: Text('Phòng')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    // 👇 Tạo các hàng từ dữ liệu API
                    rows: List.generate(
                      schedules.length,
                          (index) => _buildDataRow(index + 1, schedules[index]),
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
  DataRow _buildDataRow(int stt, Schedule schedule) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(schedule.teacherName)),
        DataCell(Text(schedule.classCode)),
        DataCell(Text(schedule.courseName)),
        DataCell(Text(schedule.semester)),
        DataCell(Text(schedule.roomName)),
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