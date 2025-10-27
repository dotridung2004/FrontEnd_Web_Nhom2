import 'package:flutter/material.dart';

class KhoaScreen extends StatelessWidget {
  const KhoaScreen({Key? key}) : super(key: key);

  // Màu sắc cho các icon
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  @override
  Widget build(BuildContext context) {
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
                "Khoa",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Xử lý sự kiện nhấn nút Thêm
                    },
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Thêm", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tluBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
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
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor:
                        MaterialStateProperty.all(tluBlue),
                        headingTextStyle: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(label: Text('STT')),
                          DataColumn(label: Text('Mã khoa')),
                          DataColumn(label: Text('Tên khoa')),
                          DataColumn(label: Text('Số lượng giảng viên')),
                          DataColumn(label: Text('Số lượng bộ môn')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: [
                          // Dữ liệu mẫu
                          _buildDataRow("1", "CNTT", "Công nghệ thông tin", "5", "5"),
                          _buildDataRow("2", "CT", "Công trình", "4", "4"),
                          _buildDataRow("3", "CK", "Cơ khí", "5", "5"),
                        ],
                      ),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  /// Helper để tạo một hàng dữ liệu (DataRow)
  DataRow _buildDataRow(
      String stt, String maKhoa, String tenKhoa, String slGV, String slBM) {
    return DataRow(
      cells: [
        DataCell(Text(stt)),
        DataCell(Text(maKhoa)),
        DataCell(Text(tenKhoa)),
        DataCell(Text(slGV)),
        DataCell(Text(slBM)),
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