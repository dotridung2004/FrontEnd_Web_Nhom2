// lib/screens/tai_khoan_screen.dart

import 'package:flutter/material.dart';
import '../models/app_user.dart';

// Dòng này sẽ hoạt động sau khi bạn làm Bước 1 và 2.
// Nó trỏ thẳng đến file api_service.dart trong thư mục table của bạn.
import 'package:web_nhom2/api_service.dart';

class TaiKhoanScreen extends StatefulWidget {
  const TaiKhoanScreen({Key? key}) : super(key: key);

  @override
  _TaiKhoanScreenState createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _apiService.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final users = snapshot.data!;
                  return _buildDataTable(users);
                }
                return const Center(child: Text('Không có dữ liệu tài khoản.'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EBA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<AppUser> users) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFF0D6EBA).withOpacity(0.9)),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          columns: const [
            DataColumn(label: Text('STT')),
            DataColumn(label: Text('Tên người dùng')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Vai trò')),
            DataColumn(label: Text('Ngày tạo')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: users.map((user) => DataRow(
            cells: [
              DataCell(Text(user.id.toString())),
              DataCell(Text(user.username)),
              DataCell(Text(user.email)),
              DataCell(Text(user.role)),
              DataCell(Text(user.creationDate)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () {},
                      tooltip: 'Sửa',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {},
                      tooltip: 'Xóa',
                    ),
                  ],
                ),
              ),
            ],
          )).toList(),
        ),
      ),
    );
  }
}