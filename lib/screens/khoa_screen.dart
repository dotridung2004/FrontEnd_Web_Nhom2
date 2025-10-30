import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/department.dart';
// Import màn hình chi tiết mới
import '../models/department_detail.dart';
// Import (hoặc định nghĩa) model User/Teacher
// import '../models/user.dart';

// --- DỮ LIỆU GIẢ (MOCK DATA) ---
class MockTeacher {
  final int id;
  final String name;
  MockTeacher(this.id, this.name);
}
// --- HẾT DỮ LIỆU GIẢ ---

class KhoaScreen extends StatefulWidget {
  const KhoaScreen({Key? key}) : super(key: key);

  @override
  State<KhoaScreen> createState() => _KhoaScreenState();
}

class _KhoaScreenState extends State<KhoaScreen> {
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State Quản lý dữ liệu
  final ApiService _apiService = ApiService();
  List<Department> _allDepartments = [];
  List<Department> _filteredDepartments = [];
  List<MockTeacher> _allTeachers = []; // Danh sách giảng viên cho dropdown
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  /// Tải (hoặc tải lại) tất cả dữ liệu cần thiết
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final departmentsFuture = _apiService.fetchDepartments();
      final teachersFuture = _fetchTeachers();

      final results = await Future.wait([departmentsFuture, teachersFuture]);

      final departments = results[0] as List<Department>;
      final teachers = results[1] as List<MockTeacher>;

      setState(() {
        _allDepartments = departments;
        _allTeachers = teachers;
        _filterDepartments();
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi khi tải dữ liệu: $e', isError: true);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // (Tạm thời mock, sau này sẽ gọi API)
  Future<List<MockTeacher>> _fetchTeachers() async {
    // TODO: Thay thế bằng API thật
    await Future.delayed(Duration(milliseconds: 100)); // Giả lập chờ
    return [
      MockTeacher(1, 'Nguyễn Văn A'),
      MockTeacher(2, 'Trần Thị B'),
      MockTeacher(3, 'Đỗ Văn C'),
    ];
  }


  /// Lọc danh sách khoa dựa trên _searchQuery (Tìm kiếm phía client)
  void _filterDepartments() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredDepartments = List.from(_allDepartments);
      } else {
        _filteredDepartments = _allDepartments
            .where((dept) =>
            dept.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return _buildContent(context, _filteredDepartments);
  }

  Widget _buildContent(BuildContext context, List<Department> departments) {
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
                onPressed: () {
                  _showDepartmentDialog(); // Gọi dialog Thêm
                },
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm khoa",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo tên khoa",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterDepartments();
                  },
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

                    // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
                    columns: const [
                      DataColumn(label: Text('STT')),
                      // DataColumn(label: Text('Mã khoa')), // (Bỏ)
                      DataColumn(label: Text('Tên khoa')),
                      DataColumn(label: Text('Số lượng giảng viên')),
                      DataColumn(label: Text('Số lượng bộ môn')), // (Thêm lại)
                      DataColumn(label: Text('Thao tác')),
                    ],
                    // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

                    rows: List.generate(
                      departments.length,
                          (index) =>
                          _buildDataRow(index + 1, departments[index]),
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

  DataRow _buildDataRow(int stt, Department department) {
    return DataRow(
      // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
      cells: [
        DataCell(Text(stt.toString())),
        // DataCell(Text(department.code)), // (Bỏ)
        DataCell(Text(department.name)),
        DataCell(Text(department.teacherCount.toString())),
        DataCell(Text(department.divisionCount.toString())), // (Thêm lại)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: Icon(Icons.info_outline, color: iconView),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DepartmentDetailScreen(
                          departmentId: department.id,
                        ),
                      ),
                    );
                  },
                  tooltip: "Xem"),
              IconButton(
                  icon: Icon(Icons.edit_outlined, color: iconEdit),
                  onPressed: () {
                    _showDepartmentDialog(department: department);
                  },
                  tooltip: "Sửa"),
              IconButton(
                  icon: Icon(Icons.delete_outline, color: iconDelete),
                  onPressed: () {
                    _showDeleteConfirmation(department);
                  },
                  tooltip: "Xóa"),
            ],
          ),
        ),
      ],
      // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
    );
  }

  // ===================================================
  // HÀM _showDepartmentDialog (Không thay đổi)
  // (Vẫn giữ 'Mã khoa' trong dialog để Thêm/Sửa)
  // ===================================================
  void _showDepartmentDialog({Department? department}) {
    final bool isEditing = department != null;
    final _formKey = GlobalKey<FormState>();

    final _codeController =
    TextEditingController(text: isEditing ? department.code : '');
    final _nameController =
    TextEditingController(text: isEditing ? department.name : '');
    MockTeacher? _selectedHead;

    if (isEditing && department.headId != null) {
      try {
        _selectedHead = _allTeachers.firstWhere(
                (teacher) => teacher.id == department.headId);
      } catch (e) {
        _selectedHead = null;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: tluBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'CHỈNH SỬA THÔNG TIN KHOA' : 'THÊM KHOA MỚI',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  tooltip: "Đóng",
                ),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Mã khoa', isRequired: true),
                              TextFormField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập mã khoa',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mã khoa';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormLabel('Tên khoa', isRequired: true),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tên khoa',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tên khoa';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormLabel('Trưởng khoa', isRequired: true),
                    DropdownButtonFormField<MockTeacher>(
                      value: _selectedHead,
                      hint: Text('-- Chọn trưởng khoa --'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _allTeachers.map((MockTeacher teacher) {
                        return DropdownMenuItem<MockTeacher>(
                          value: teacher,
                          child: Text(teacher.name),
                        );
                      }).toList(),
                      onChanged: (MockTeacher? newValue) {
                        _selectedHead = newValue;
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn trưởng khoa';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy bỏ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _handleSubmit(
                    context: context,
                    isEditing: isEditing,
                    departmentId: department?.id,
                    code: _codeController.text,
                    name: _nameController.text,
                    headId: _selectedHead?.id,
                  );
                }
              },
              child: Text('Xác nhận'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
          children: [
            if (isRequired)
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // CÁC HÀM LOGIC (Không thay đổi)
  // ===================================================

  void _handleSubmit({
    required BuildContext context,
    required bool isEditing,
    int? departmentId,
    required String code,
    required String name,
    int? headId,
  }) async {
    try {
      final data = {
        'code': code,
        'name': name,
        'head_id': headId,
      };

      if (isEditing) {
        await _apiService.updateDepartment(departmentId!, data);
        _showSnackBar('Cập nhật khoa thành công!', isError: false);
      } else {
        await _apiService.createDepartment(data);
        _showSnackBar('Thêm khoa mới thành công!', isError: false);
      }

      if (mounted) Navigator.of(context).pop();
      _refreshData();
    } catch (e) {
      _showSnackBar('Đã xảy ra lỗi: $e', isError: true);
    }
  }

  void _showDeleteConfirmation(Department department) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa khoa "${department.name}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _apiService.deleteDepartment(department.id);
                  _showSnackBar('Xóa khoa thành công!', isError: false);
                  if (mounted) Navigator.of(context).pop();
                  _refreshData();
                } catch (e) {
                  _showSnackBar('Lỗi khi xóa: $e', isError: true);
                }
              },
              child: Text('Xóa'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: iconDelete, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}