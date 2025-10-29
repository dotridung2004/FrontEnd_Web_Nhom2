import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/major.dart';

class MajorScreen extends StatefulWidget {
  const MajorScreen({Key? key}) : super(key: key);

  @override
  _MajorScreenState createState() => _MajorScreenState();
}

class _MajorScreenState extends State<MajorScreen> {
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  late Future<List<Major>> _majorsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _majorsFuture = _apiService.fetchMajors();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Major>>(
      future: _majorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải dữ liệu: ${snapshot.error}', // Giữ Tiếng Việt
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildContent(context, []);
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Major> majors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nút Thêm và Tìm kiếm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () { /* TODO: Xử lý Thêm */ },
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm ngành học", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // Đổi Tiếng Việt
                style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm", // Đổi Tiếng Việt
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                    // Đổi Tiếng Việt
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Mã ngành')),
                      DataColumn(label: Text('Tên ngành')),
                      DataColumn(label: Text('Khoa')),
                      DataColumn(label: Text('Số lượng GV')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: List.generate(
                      majors.length,
                          (index) => _buildDataRow(index + 1, majors[index]),
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

  DataRow _buildDataRow(int stt, Major major) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(major.code)),
        DataCell(Text(major.name)),
        DataCell(Text(major.departmentName)),
        DataCell(Text(major.teacherCount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Đổi Tiếng Việt
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
