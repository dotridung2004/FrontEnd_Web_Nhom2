// file: lib/screens/giang_vien_screen.dart

import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/lecturer.dart';

class GiangVienScreen extends StatefulWidget {
  const GiangVienScreen({Key? key}) : super(key: key);

  @override
  State<GiangVienScreen> createState() => _GiangVienScreenState();
}

class _GiangVienScreenState extends State<GiangVienScreen> {
  // --- State and Colors ---
  static const Color tluBlue = Color(0xFF005A9C);
  static const Color iconView = Colors.blue;
  static const Color iconEdit = Colors.green;
  static const Color iconDelete = Colors.red;
  static const Color screenBg = Color(0xFFF0F4F8);

  final ApiService _apiService = ApiService();
  late Future<List<Lecturer>> _lecturersFuture;

  // Dữ liệu giả cho Khoa
  final List<String> _departments = ['Công nghệ thông tin', 'Công trình', 'Cơ khí', 'Kinh tế'];
  String? _selectedDepartment;
  final TextEditingController _searchController = TextEditingController();

  List<Lecturer> _allLecturers = [];
  List<Lecturer> _filteredLecturers = [];

  @override
  void initState() {
    super.initState();
    _loadLecturers();
    _searchController.addListener(_filterData);
  }

  void _loadLecturers() {
    _lecturersFuture = _apiService.fetchLecturers();
    _lecturersFuture.then((data) {
      if (mounted) {
        setState(() {
          _allLecturers = data;
          _filteredLecturers = data;
        });
      }
    });
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLecturers = _allLecturers.where((lecturer) {
        final departmentMatch = _selectedDepartment == null || lecturer.departmentName == _selectedDepartment;
        final searchMatch = lecturer.fullName.toLowerCase().contains(query) ||
            lecturer.lecturerCode.toLowerCase().contains(query) ||
            lecturer.email.toLowerCase().contains(query);
        return departmentMatch && searchMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Giảng viên",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            _buildControls(),
            const SizedBox(height: 16),
            FutureBuilder<List<Lecturer>>(
              future: _lecturersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _allLecturers.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && _allLecturers.isEmpty) {
                  return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (_filteredLecturers.isEmpty && snapshot.connectionState == ConnectionState.done) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                        child: Text(
                          'Không tìm thấy giảng viên nào.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        )
                    ),
                  );
                }
                return _buildDataTable();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 👇 HÀM NÀY ĐÃ ĐƯỢC CẬP NHẬT
  Widget _buildControls() {
    return Row(
      // Tách nút "Thêm" và nhóm control ra hai đầu
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Nút Thêm (bên trái)
        ElevatedButton(
          onPressed: () { /* TODO: Logic cho nút Thêm */ },
          style: ElevatedButton.styleFrom(
            backgroundColor: tluBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            minimumSize: const Size(0, 50),
          ),
          child: const Text("Thêm", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),

        // Nhóm control (bên phải)
        Row(
          children: [
            // Dropdown Khoa với chiều rộng cố định
            SizedBox(
              width: 250, // <-- Đặt chiều rộng cố định
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    hint: const Text("Khoa"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Tất cả Khoa"),
                      ),
                      ..._departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDepartment = newValue;
                        _filterData();
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Thanh Tìm kiếm với chiều rộng cố định
            SizedBox(
              width: 300, // <-- Đặt chiều rộng cố định
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm",
                  suffixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(tluBlue),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  dataRowMinHeight: 52.0,
                  dataRowMaxHeight: 52.0,
                  columns: const [
                    DataColumn(label: Text('STT')),
                    DataColumn(label: Text('Mã giảng viên')),
                    DataColumn(label: Text('Tên giảng viên')),
                    DataColumn(label: Text('Ngày sinh')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Số điện thoại')),
                    DataColumn(label: Text('Khoa')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: List.generate(
                    _filteredLecturers.length,
                        (index) => _buildDataRow(index + 1, _filteredLecturers[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  DataRow _buildDataRow(int index, Lecturer lecturer) {
    return DataRow(
      cells: [
        DataCell(Text(index.toString())),
        DataCell(Text(lecturer.lecturerCode)),
        DataCell(Text(lecturer.fullName)),
        DataCell(Text(lecturer.dob ?? 'N/A')),
        DataCell(Text(lecturer.email)),
        DataCell(Text(lecturer.phoneNumber ?? 'N/A')),
        DataCell(Text(lecturer.departmentName)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.info_outline, color: iconView, size: 20), onPressed: () {}, tooltip: "Xem", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.edit_outlined, color: iconEdit, size: 20), onPressed: () {}, tooltip: "Sửa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.delete_outline, color: iconDelete, size: 20), onPressed: () {}, tooltip: "Xóa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
          ],
        )),
      ],
    );
  }
}