// Tên file: lib/screens/major_screen.dart
// *** ĐÃ CẬP NHẬT: Tối ưu hóa Xóa (không reload) ***

import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/major.dart'; // Model cho danh sách (mới)
import '../models/major_detail.dart'; // Model cho chi tiết/form (cũ)
import '../models/department.dart'; // Cần cho Dropdown Khoa
import 'dart:math'; // Cần cho hàm min()

// ✅ SỬA LỖI: Thêm extension firstOrNull (vì code của _SaveClassCourseFormState CẦN nó)
extension FirstOrNullExtension<E> on Iterable<E> {
  E? firstOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}


class MajorScreen extends StatefulWidget {
  const MajorScreen({Key? key}) : super(key: key);

  @override
  _MajorScreenState createState() => _MajorScreenState();
}

class _MajorScreenState extends State<MajorScreen> {
  // --- Colors ---
  final Color tluBlue = const Color(0xFF005A9C);
  final Color screenBg = Color(0xFFF0F4F8);
  final Color dialogBg = Colors.white;
  final Color iconView = Colors.blue.shade700;
  final Color iconEdit = Colors.green.shade700;
  final Color iconDelete = Color(0xFFD32F2F);
  final Color okGreen = Color(0xFF4CAF50);
  final Color cancelRed = Color(0xFFF44336);

  // --- API & State ---
  final ApiService _apiService = ApiService();
  late Future<void> _dataLoader;
  List<Major> _allMajors = [];
  List<Major> _filteredMajors = [];
  List<Department> _allDepartments = [];

  // --- Search State ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- Pagination State ---
  int _currentPage = 1;
  final int _rowsPerPage = 10;
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    _dataLoader = _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Tải dữ liệu ban đầu (Ngành và Khoa)
  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _apiService.fetchMajors(),
        _apiService.fetchDepartments(),
      ]);

      if (mounted) {
        setState(() {
          _allMajors = results[0] as List<Major>;
          _allDepartments = results[1] as List<Department>;
          _totalRows = _allMajors.length;
          _applyFiltersAndPagination();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'),
              backgroundColor: iconDelete),
        );
      }
    }
  }

  /// Xử lý XÓA CỤC BỘ (thay vì reload)
  void _handleLocalDelete(int majorId) {
    setState(() {
      // 1. Xóa khỏi danh sách chính
      _allMajors.removeWhere((major) => major.id == majorId);

      // 2. Cập nhật lại tổng số hàng
      _totalRows = _allMajors.length;

      // 3. Kiểm tra xem trang hiện tại có bị rỗng không
      int totalPages = (_totalRows / _rowsPerPage).ceil();
      if (totalPages == 0) totalPages = 1;
      if (_currentPage > totalPages) {
        _currentPage = totalPages;
      }

      // 4. Áp dụng lại filter và phân trang
      _applyFiltersAndPagination();
    });
  }


  /// Lọc và Phân trang
  void _applyFiltersAndPagination() {
    List<Major> temp = List.from(_allMajors);

    // 1. Filtering (Search)
    if (_searchQuery.isNotEmpty) {
      String query = _searchQuery.toLowerCase();
      temp = temp.where((major) {
        return (major.code.toLowerCase().contains(query) ||
            major.name.toLowerCase().contains(query) ||
            major.departmentName.toLowerCase().contains(query));
      }).toList();
    }

    _totalRows = temp.length;

    // 3. Pagination
    int startIndex = (_currentPage - 1) * _rowsPerPage;
    if (startIndex < 0 || startIndex >= _totalRows) {
      startIndex = 0;
      _currentPage = 1;
    }

    int endIndex = min(startIndex + _rowsPerPage, _totalRows);

    setState(() {
      _filteredMajors = temp.sublist(startIndex, endIndex);
    });
  }

  /// Xử lý khi nội dung ô tìm kiếm thay đổi
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1;
      _applyFiltersAndPagination();
    });
  }

  /// Xử lý khi nhấn nút chuyển trang
  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
      _applyFiltersAndPagination();
    });
  }


  // ==================================================================
  // BUILD WIDGETS
  // (Giữ nguyên)
  // ==================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg,
      body: FutureBuilder<void>(
        future: _dataLoader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi khi tải dữ liệu: ${snapshot.error}',
                style: TextStyle(color: iconDelete),
              ),
            );
          }
          return _buildContent(context, _filteredMajors);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Major> majors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm ngành học",
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
                    hintText: "Tìm kiếm Mã, Tên, Khoa...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: tluBlue, width: 2.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                LayoutBuilder(builder: (context, constraints) {
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
                          DataColumn(label: Text('Mã ngành')),
                          DataColumn(label: Text('Tên ngành')),
                          DataColumn(label: Text('Khoa')),
                          DataColumn(label: Text('Số lượng GV')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        rows: List.generate(
                          majors.length,
                              (index) => _buildDataRow(
                              (_currentPage - 1) * _rowsPerPage + index + 1,
                              majors[index]),
                        ),
                      ),
                    ),
                  );
                }),
                _buildPaginationControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    int totalPages = (_totalRows / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $_currentPage / $totalPages (Tổng: $_totalRows)',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.first_page),
                onPressed: _currentPage == 1 ? null : () => _onPageChanged(1),
                tooltip: "Trang đầu",
              ),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage == 1
                    ? null
                    : () => _onPageChanged(_currentPage - 1),
                tooltip: "Trang trước",
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _currentPage == totalPages
                    ? null
                    : () => _onPageChanged(_currentPage + 1),
                tooltip: "Trang sau",
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: _currentPage == totalPages
                    ? null
                    : () => _onPageChanged(totalPages),
                tooltip: "Trang cuối",
              ),
            ],
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
              IconButton(
                icon: Icon(Icons.info_outline, color: iconView),
                onPressed: () => _showViewDialog(major.id),
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEdit),
                onPressed: () => _showEditDialog(major.id),
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDelete),
                onPressed: () =>
                    _showDeleteDialog(major.id, major.name),
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================================================================
  // DIALOGS (Add, Edit, View, Delete)
  // ==================================================================

  /// Hiển thị Dialog THÊM MỚI
  void _showAddDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _MajorFormDialog(
          majorId: null,
          apiService: _apiService,
          allDepartments: _allDepartments,
          onSuccess: (message, newMajor) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );

            setState(() {
              _allMajors.insert(0, newMajor);
              _totalRows = _allMajors.length;
              _applyFiltersAndPagination();
            });
          },
        );
      },
    );
  }

  /// Hiển thị Dialog CHỈNH SỬA
  void _showEditDialog(int majorId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _MajorFormDialog(
          majorId: majorId,
          apiService: _apiService,
          allDepartments: _allDepartments,
          onSuccess: (message, updatedMajor) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );

            setState(() {
              final index = _allMajors.indexWhere((m) => m.id == updatedMajor.id);
              if (index != -1) {
                _allMajors[index] = updatedMajor;
              }
              // Sắp xếp lại để mục vừa cập nhật lên đầu
              _allMajors.sort((a, b) {
                if (a.updatedAt == null || b.updatedAt == null) return 0;
                return b.updatedAt!.compareTo(a.updatedAt!);
              });

              _applyFiltersAndPagination();
            });
          },
        );
      },
    );
  }

  /// Hiển thị Dialog XEM CHI TIẾT
  void _showViewDialog(int majorId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return FutureBuilder<MajorDetail>(
          future: _apiService.fetchMajorDetails(majorId),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = Center(
                heightFactor: 5,
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError || !snapshot.hasData) {
              content = Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text("Lỗi: Không thể tải chi tiết ngành. ${snapshot.error}"),
              );
            } else {
              final detail = snapshot.data!;
              content = SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Thông tin cơ bản",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tluBlue,
                        fontSize: 16,
                      ),
                    ),
                    Divider(height: 20, color: Colors.grey.shade300),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildReadOnlyField("Mã ngành:", detail.maNganh),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField("Tên ngành:", detail.tenNganh),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildReadOnlyField(
                              "Khoa phụ trách:", detail.tenKhoa ?? 'N/A'),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField(
                              "Số lượng giảng viên:", detail.teacherCount.toString()),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildReadOnlyField("Mô tả:", detail.moTa ?? 'Không có mô tả.'),
                    SizedBox(height: 24),
                    Text(
                      "Danh sách giảng viên (${detail.teacherCount})",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tluBlue,
                        fontSize: 16,
                      ),
                    ),
                    Divider(height: 20, color: Colors.grey.shade300),
                    _buildTeacherTable(detail.teachers),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              backgroundColor: dialogBg,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 700, minWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: tluBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8.0),
                          topRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Thông Tin Ngành",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(child: content),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            child: Text("Quay lại"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tluBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  /// Widget helper cho dialog xem chi tiết
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300)
          ),
          child: SelectableText(
            value,
            style: TextStyle(fontSize: 16, color: Colors.black87),
            minLines: 1,
            maxLines: 5,
          ),
        ),
      ],
    );
  }

  /// Widget helper để vẽ bảng giảng viên
  Widget _buildTeacherTable(List<TeacherSummary> teachers) {
    if (teachers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300)
        ),
        child: Center(child: Text("Chưa có giảng viên nào thuộc ngành này.")),
      );
    }

    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 652),
          child: DataTable(
            headingRowHeight: 40,
            dataRowHeight: 48,
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text("STT", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Họ tên", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: teachers.asMap().entries.map((entry) {
              int index = entry.key;
              TeacherSummary teacher = entry.value;
              return DataRow(
                  cells: [
                    DataCell(Text((index + 1).toString())),
                    DataCell(Text(teacher.hoTen)),
                    DataCell(Text(teacher.email)),
                  ]
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Hiển thị Dialog XÁC NHẬN XÓA
  void _showDeleteDialog(int majorId, String majorName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _DeleteMajorDialog(
          apiService: _apiService,
          majorId: majorId,
          majorName: majorName,
          dialogBg: dialogBg,
          cancelRed: cancelRed,
          okGreen: okGreen,
          iconDelete: iconDelete,
          onDeleted: () {
            _handleLocalDelete(majorId);
          },
        );
      },
    );
  }
}

// ==================================================================
// DIALOG FORM (Thêm/Sửa)
// ==================================================================
class _MajorFormDialog extends StatefulWidget {
  final int? majorId;
  final ApiService apiService;
  final List<Department> allDepartments;
  final Function(String, Major) onSuccess;

  const _MajorFormDialog({
    Key? key,
    this.majorId,
    required this.apiService,
    required this.allDepartments,
    required this.onSuccess,
  }) : super(key: key);

  @override
  __MajorFormDialogState createState() => __MajorFormDialogState();
}

class __MajorFormDialogState extends State<_MajorFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Color tluBlue = Color(0xFF005A9C);
  final Color errorRed = Color(0xFFD32F2F);
  final Color okGreen = Color(0xFF4CAF50);
  final Color cancelRed = Color(0xFFF44336);

  // --- Controllers ---
  late TextEditingController _maNganhController;
  late TextEditingController _tenNganhController;
  late TextEditingController _moTaController;
  int? _selectedKhoaId;

  // --- State ---
  bool _isEditMode = false;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _maNganhController = TextEditingController();
    _tenNganhController = TextEditingController();
    _moTaController = TextEditingController();
    _isEditMode = widget.majorId != null;
    if (_isEditMode) {
      _loadMajorDetails();
    }
  }

  @override
  void dispose() {
    _maNganhController.dispose();
    _tenNganhController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  /// Tải chi tiết ngành (chỉ dùng cho chế độ Sửa)
  Future<void> _loadMajorDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = null;
    });
    try {
      final detail = await widget.apiService.fetchMajorDetails(widget.majorId!);
      setState(() {
        _maNganhController.text = detail.maNganh;
        _tenNganhController.text = detail.tenNganh;
        _moTaController.text = detail.moTa ?? '';
        _selectedKhoaId = detail.khoaId;
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = "Lỗi tải chi tiết: $e";
      });
    }
  }

  /// Xử lý khi nhấn nút "Xác nhận" (Thêm hoặc Sửa)
  Future<void> _handleSubmit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedKhoaId == null) {
      setState(() {
        _errorMessage = "Vui lòng chọn Khoa phụ trách.";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = {
      'ma_nganh': _maNganhController.text,
      'ten_nganh': _tenNganhController.text,
      'mo_ta': _moTaController.text.isNotEmpty ? _moTaController.text : null,
      'khoa_id': _selectedKhoaId,
    };

    try {
      if (_isEditMode) {
        final Major updatedMajor = await widget.apiService.updateMajor(widget.majorId!, data);
        widget.onSuccess("Cập nhật ngành học thành công!", updatedMajor);
      } else {
        final Major newMajor = await widget.apiService.createMajor(data);
        widget.onSuccess("Thêm ngành học mới thành công!", newMajor);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Helper widget cho trường nhập liệu (Label + Field)
  Widget _buildTextField(
      {required BuildContext context,
        required String label,
        required TextEditingController controller,
        required String hint,
        bool isRequired = false,
        int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            if (isRequired)
              Text(" *",
                  style: TextStyle(color: errorRed, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: tluBlue, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label không được để trống';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Helper widget cho trường Dropdown (Label + Field)
  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required Function(int?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            Text(" *",
                style: TextStyle(color: errorRed, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: value,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: tluBlue, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = _isEditMode ? "Chỉnh sửa thông tin ngành" : "Thêm ngành mới";

    // ✅ SỬA LỖI: Xóa WillPopScope
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600, minWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Thanh Tiêu đề
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: tluBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    // ✅ SỬA LỖI: Chỉ gọi pop
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 2. Nội dung Form
            _isLoadingDetails
                ? Center(
              heightFactor: 5,
              child: CircularProgressIndicator(),
            )
                : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        color: errorRed.withOpacity(0.1),
                        child: Text(_errorMessage!,
                            style: TextStyle(color: errorRed)),
                      ),
                    if (_errorMessage != null) SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            label: "Mã ngành",
                            controller: _maNganhController,
                            hint: "Nhập mã ngành",
                            isRequired: true,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            context: context,
                            label: "Tên ngành",
                            controller: _tenNganhController,
                            hint: "Nhập tên ngành",
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildDropdownField(
                      context: context,
                      label: "Khoa phụ trách",
                      hint: "-- Chọn Khoa phụ trách --",
                      value: _selectedKhoaId,
                      items: widget.allDepartments
                          .map((Department dept) {
                        return DropdownMenuItem<int>(
                          value: dept.id,
                          child: Text(dept.name),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedKhoaId = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      label: "Mô tả",
                      controller: _moTaController,
                      hint: "Nhập mô tả",
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Các nút
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    child: Text("Hủy", style: TextStyle(color: cancelRed)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cancelRed),
                      padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    // ✅ SỬA LỖI: Chỉ gọi pop
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    child: _isLoading
                        ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : Text("Xác nhận"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: okGreen,
                      foregroundColor: Colors.white,
                      padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// DIALOG XÁC NHẬN XÓA (Widget có State riêng)
// (Giữ nguyên)
// ==================================================================
class _DeleteMajorDialog extends StatefulWidget {
  final ApiService apiService;
  final int majorId;
  final String majorName;
  final Function onDeleted; // Callback để reload data

  // Màu sắc truyền từ widget cha
  final Color dialogBg;
  final Color cancelRed;
  final Color okGreen;
  final Color iconDelete;


  const _DeleteMajorDialog({
    Key? key,
    required this.apiService,
    required this.majorId,
    required this.majorName,
    required this.onDeleted,
    required this.dialogBg,
    required this.cancelRed,
    required this.okGreen,
    required this.iconDelete,
  }) : super(key: key);

  @override
  __DeleteMajorDialogState createState() => __DeleteMajorDialogState();
}

class __DeleteMajorDialogState extends State<_DeleteMajorDialog> {
  bool _isLoading = false;

  Future<void> _handleDelete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.deleteMajor(widget.majorId);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Đã xóa ngành '${widget.majorName}' thành công."),
            backgroundColor: Colors.green),
      );

      widget.onDeleted();

    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Lỗi khi xóa: $e"),
            backgroundColor: widget.iconDelete),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: widget.dialogBg,
      title: Center(
        child: Text(
          "Thông báo!",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
      ),
      content: Text(
        "Bạn chắc chắn muốn xóa ngành \"${widget.majorName}\"?",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey.shade800,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
      actions: [
        OutlinedButton(
          child: Text("Hủy", style: TextStyle(color: widget.cancelRed, fontSize: 16, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: widget.cancelRed, width: 2),
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minimumSize: Size(120, 50),
          ),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.okGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minimumSize: Size(120, 50),
          ),
          onPressed: _isLoading ? null : _handleDelete,
          child: _isLoading
              ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : Text("Xác nhận", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}