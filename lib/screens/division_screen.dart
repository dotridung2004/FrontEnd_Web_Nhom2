import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/division.dart';
import '../models/department.dart'; // Import Department để dùng trong Dropdown
import '../models/course.dart';    // Import Course để xem chi tiết
import '../table/user.dart';       // Import User để xem chi tiết
import '../models/division_detail.dart'; // Import model chi tiết
import 'dart:async'; // Import để sử dụng Timer (cho debounce)
import 'package:collection/collection.dart'; // Import collection
import 'dart:math'; // Import cho hàm min

class DivisionScreen extends StatefulWidget {
  const DivisionScreen({Key? key}) : super(key: key);

  @override
  _DivisionScreenState createState() => _DivisionScreenState();
}

class _DivisionScreenState extends State<DivisionScreen> {
  // --- Màu sắc ---
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconViewColor = Colors.blue;
  final Color iconEditColor = Colors.green;
  final Color iconDeleteColor = Colors.red;
  final Color cancelColor = Colors.red;
  final Color confirmColor = Colors.green.shade600;

  final ApiService _apiService = ApiService();

  // State cho Dropdown Khoa
  List<Department> _departments = [];
  bool _isLoadingDepartments = false;

  // --- State cho Phân trang và Tìm kiếm (FRONT-END) ---
  List<Division> _allDivisions = []; // Danh sách đầy đủ
  List<Division> _filteredDivisions = []; // Danh sách đã lọc
  List<Division> _pagedDivisions = []; // Danh sách hiển thị trên trang

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  final int _rowsPerPage = 10; // Cố định 10 hàng/trang
  bool _isLoading = true; // Cờ loading chính
  String _currentSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm tải dữ liệu ban đầu
  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _isLoading = true; });

    try {
      // Tải song song Khoa (cho dropdown) và Bộ môn (danh sách chính)
      final departmentsFuture = _fetchDepartments();
      // 👇 **** SỬA ĐỔI: Gọi hàm fetchDivisions mới **** 👇
      final divisionsFuture = _apiService.fetchDivisions();

      final results = await Future.wait([departmentsFuture, divisionsFuture]);

      final departments = results[0] as List<Department>;
      final divisions = results[1] as List<Division>;

      if (mounted) {
        setState(() {
          _departments = departments;
          // Sắp xếp danh sách (ví dụ: mới nhất lên đầu)
          _allDivisions = divisions;
          _filteredDivisions = divisions;
          _updatePagination(divisions); // Cập nhật phân trang
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi tải dữ liệu ban đầu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  // Hàm tải danh sách khoa (cho dropdown)
  Future<List<Department>> _fetchDepartments() async {
    if (mounted) setState(() { _isLoadingDepartments = true; });
    try {
      final departments = await _apiService.fetchDepartments();
      if (mounted) setState(() { _isLoadingDepartments = false; });
      return departments;
    } catch (e) {
      if (mounted) setState(() { _isLoadingDepartments = false; });
      _showSnackBar('Lỗi tải danh sách khoa: $e', isError: true);
      return [];
    }
  }

  // Hàm refresh (tải lại toàn bộ)
  // 👇 **** SỬA ĐỔI: Đổi tên hàm và logic **** 👇
  void _refreshDivisionList({bool clearSearch = false}) {
    if (clearSearch) {
      _currentSearchQuery = '';
      _searchController.clear();
    }
    _loadInitialData(); // Tải lại tất cả từ đầu
  }

  // --- Hàm xử lý Phân trang & Tìm kiếm (FRONT-END) ---

  // (Hàm này được gọi bởi Debounce)
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _currentSearchQuery = _searchController.text;
      _filterAndPaginateList(); // (Gọi hàm lọc)
    });
  }

  // (Hàm mới: Lọc danh sách)
  void _filterAndPaginateList() {
    if (!mounted) return;
    setState(() {
      // 1. Lọc
      if (_currentSearchQuery.isEmpty) {
        _filteredDivisions = List.from(_allDivisions);
      } else {
        final query = _currentSearchQuery.toLowerCase();
        _filteredDivisions = _allDivisions.where((division) {
          return division.name.toLowerCase().contains(query) ||
              division.code.toLowerCase().contains(query) ||
              division.departmentName.toLowerCase().contains(query);
        }).toList();
      }
      // 2. Cập nhật phân trang
      _updatePagination(_filteredDivisions, goToFirstPage: true);
    });
  }

  // (Hàm mới: Cập nhật biến phân trang)
  void _updatePagination(List<Division> list, {bool goToFirstPage = false}) {
    if (!mounted) return;
    setState(() {
      _totalItems = list.length;
      _lastPage = (_totalItems / _rowsPerPage).ceil();
      if (_lastPage == 0) _lastPage = 1;

      if (goToFirstPage) {
        _currentPage = 1;
      } else {
        if (_currentPage > _lastPage) _currentPage = _lastPage;
      }

      // 3. Lấy danh sách cho trang hiện tại
      int startIndex = (_currentPage - 1) * _rowsPerPage;
      int endIndex = min(startIndex + _rowsPerPage, _totalItems);

      _pagedDivisions = (startIndex < _totalItems)
          ? list.sublist(startIndex, endIndex)
          : [];
    });
  }

  // (Hàm mới: Chuyển trang)
  void _goToPage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    if (mounted) {
      setState(() {
        _currentPage = page;
        _updatePagination(_filteredDivisions); // Cập nhật lại ds trang
      });
    }
  }
  // --- Kết thúc Phân trang & Tìm kiếm ---

  @override
  Widget build(BuildContext context) {
    // 👇 **** SỬA ĐỔI: Dùng _pagedDivisions **** 👇
    return _buildContent(context, _pagedDivisions);
  }

  Widget _buildContent(BuildContext context, List<Division> divisionsToDisplay) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoadingDepartments ? null : () => _showAddEditDivisionDialog(null),
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm bộ môn", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo tên, mã, khoa...",
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () { _searchController.clear(); }
                    ) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
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
            child: LayoutBuilder(builder: (context, constraints) {
              return AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                firstChild: SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
                secondChild: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(tluBlue),
                          headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          columns: const [
                            DataColumn(label: Text('STT')),
                            // (Thêm lại cột Mã bộ môn)
                            DataColumn(label: Text('Mã bộ môn')),
                            DataColumn(label: Text('Tên bộ môn')),
                            DataColumn(label: Text('Khoa')),
                            DataColumn(label: Text('Số lượng GV')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: List.generate(
                            divisionsToDisplay.length,
                            // (Tính STT theo trang)
                                (index) => _buildDataRow(index + 1 + (_currentPage - 1) * _rowsPerPage, divisionsToDisplay[index]),
                          ),
                        ),
                      ),
                    ),
                    if (_lastPage > 1)
                      _buildPaginationControls(),
                  ],
                ),
                crossFadeState: _isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              );
            }),
          ),
          if (!_isLoading && divisionsToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(child: Text(_currentSearchQuery.isEmpty ? 'Chưa có bộ môn nào.' : 'Không tìm thấy kết quả.')),
            ),
        ],
      ),
    );
  }

  // (Bộ điều khiển phân trang - Sửa logic)
  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Trang $_currentPage / $_lastPage (Tổng: $_totalItems)'),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.first_page),
                // 👇 **** SỬA ĐỔI: Gọi _goToPage **** 👇
                onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                tooltip: 'Trang đầu',
              ),
              IconButton(
                icon: Icon(Icons.navigate_before),
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                tooltip: 'Trang trước',
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.navigate_next),
                onPressed: _currentPage < _lastPage ? () => _goToPage(_currentPage + 1) : null,
                tooltip: 'Trang sau',
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: _currentPage < _lastPage ? () => _goToPage(_lastPage) : null,
                tooltip: 'Trang cuối',
              ),
            ],
          ),
        ],
      ),
    );
  }


  DataRow _buildDataRow(int stt, Division division) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        // (Thêm lại cột Mã bộ môn)
        DataCell(Text(division.code)),
        DataCell(Text(division.name)),
        DataCell(Text(division.departmentName)),
        DataCell(Text(division.teacherCount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconViewColor),
                onPressed: () => _showViewDivisionDialog(division),
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEditColor),
                onPressed: _isLoadingDepartments ? null : () => _showAddEditDivisionDialog(division),
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDeleteColor),
                onPressed: () => _showDeleteConfirmationDialog(division),
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ---------------------------------------------------
  /// DIALOG XEM CHI TIẾT BỘ MÔN (Pop-up)
  /// (Đã sửa lại cấu trúc)
  /// ---------------------------------------------------
  void _showViewDivisionDialog(Division division) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.all(0),
          title: _buildDialogHeader('Thông Tin Bộ Môn'),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: FutureBuilder<DivisionDetail>(
              future: _apiService.fetchDivisionDetails(division.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text("Lỗi tải chi tiết", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Lỗi: ${snapshot.error}", textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                if (snapshot.hasData) {
                  return _buildDetailContent(snapshot.data!);
                }
                return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Không có dữ liệu chi tiết.")));
              },
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Quay lại'), // (Đổi nút 'Xác nhận' thành 'Quay lại')
              style: ElevatedButton.styleFrom(backgroundColor: tluBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        );
      },
    );
  }

  // (Các hàm helper cho dialog XEM - Giữ nguyên)
  Widget _buildDetailContent(DivisionDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionTitle("Thông tin cơ bản"),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildReadOnlyField("Mã bộ môn:", detail.code)),
              SizedBox(width: 16),
              Expanded(child: _buildReadOnlyField("Tên bộ môn:", detail.name)),
            ],
          ),
          SizedBox(height: 16),
          _buildReadOnlyField("Khoa:", detail.departmentName),
          SizedBox(height: 16),
          _buildReadOnlyField("Mô tả:", detail.description ?? 'Chưa có mô tả', isMultiLine: true),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildReadOnlyField("Số lượng giảng viên:", detail.teacherCount.toString())),
              SizedBox(width: 16),
              Expanded(child: _buildReadOnlyField("Số lượng môn học:", detail.courseCount.toString())),
            ],
          ),

          Divider(height: 32),
          _buildSectionTitle("Danh sách giảng viên (${detail.teachersList.length})"),
          _buildTeacherTable(detail.teachersList),

          Divider(height: 32),
          _buildSectionTitle("Danh sách môn học (${detail.coursesList.length})"),
          _buildCourseTable(detail.coursesList),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue));
  }

  Widget _buildReadOnlyField(String label, String value, {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: isMultiLine ? 12 : 10),
          constraints: BoxConstraints(minHeight: isMultiLine ? 80 : 40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value.isNotEmpty ? value : '(trống)', style: TextStyle(color: value.isNotEmpty ? Colors.black87 : Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildTeacherTable(List<User> teachers) {
    if (teachers.isEmpty) return Text('Không có giảng viên.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('STT')),
          DataColumn(label: Text('Mã giảng viên')),
          DataColumn(label: Text('Họ tên')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('SĐT')),
        ],
        rows: List.generate(teachers.length, (index) {
          final teacher = teachers[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text('GV${teacher.id.toString().padLeft(3,'0')}')),
            DataCell(Text(teacher.name)),
            DataCell(Text(teacher.email)),
            DataCell(Text(teacher.phoneNumber ?? 'N/A')), // (Sửa lỗi 'phoneNumber')
          ]);
        }),
      ),
    );
  }

  Widget _buildCourseTable(List<Course> courses) {
    if (courses.isEmpty) return Text('Không có môn học.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('STT')),
          DataColumn(label: Text('Mã MH')),
          DataColumn(label: Text('Tên môn học')),
          DataColumn(label: Text('Số tín chỉ')),
        ],
        rows: List.generate(courses.length, (index) {
          final course = courses[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text(course.code)),
            DataCell(Text(course.name)),
            DataCell(Text(course.credits.toString())),
          ]);
        }),
      ),
    );
  }


  /// ---------------------------------------------------
  /// DIALOG THÊM / CHỈNH SỬA BỘ MÔN (Pop-up)
  /// (Giữ nguyên logic)
  /// ---------------------------------------------------
  void _showAddEditDivisionDialog(Division? division) {
    final bool isEdit = division != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: isEdit ? division!.name : '');
    final _descController = TextEditingController();
    Department? _selectedDepartment;
    Future<void>? _detailsLoadingFuture;
    final _codeControllerForAdd = TextEditingController();

    if(isEdit) {
      _detailsLoadingFuture = _apiService.fetchDivisionDetails(division!.id).then((details) {
        if (mounted) {
          _descController.text = details.description ?? '';
          _selectedDepartment = _departments.firstWhereOrNull(
                  (d) => d.name == details.departmentName
          );
        }
      }).catchError((error) { /*...*/ });
    }
    if (isEdit && _departments.isNotEmpty) {
      _selectedDepartment = _departments.firstWhereOrNull(
              (d) => d.name == division!.departmentName
      );
    }

    bool _isSaving = false;

    Future<void> _saveDivision(VoidCallback onSavingStateChange) async {
      if (_formKey.currentState!.validate()) {
        onSavingStateChange();
        final data = {
          'name': _nameController.text,
          'department_id': _selectedDepartment?.id,
          'description': _descController.text,
          if (!isEdit) 'code': _codeControllerForAdd.text,
        };

        try {
          if (isEdit) {
            await _apiService.updateDivision(division!.id, data);
          } else {
            await _apiService.createDivision(data);
          }
          if (!mounted) return;
          _showSnackBar(isEdit ? 'Cập nhật bộ môn thành công!' : 'Thêm bộ môn thành công!', isError: false);
          Navigator.of(context).pop();
          _refreshDivisionList(clearSearch: !isEdit); // (Sửa logic refresh)
        }catch (e) {
          if (!mounted) return;
          _showSnackBar('Lỗi: $e', isError: true);
          onSavingStateChange();
        }
      }
    }
    Future<bool> _showExitConfirmationDialog() async {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Center(child: Text('Thông báo!', style: TextStyle(fontWeight: FontWeight.bold))),
          content: Text(
            isEdit ? 'Bạn có muốn thoát khỏi chức năng sửa thông tin bộ môn?' : 'Bạn có muốn thoát khỏi chức năng thêm thông tin bộ môn mới?',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cancelColor, side: BorderSide(color: cancelColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Xác nhận'),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              Widget formContent = FutureBuilder(
                  future: _detailsLoadingFuture,
                  builder: (context, snapshot) {
                    if (isEdit && snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    if (isEdit && snapshot.connectionState == ConnectionState.done && _selectedDepartment == null && division != null){
                      _selectedDepartment = _departments.firstWhereOrNull(
                              (d) => d.name == division.departmentName
                      );
                    }

                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (!isEdit) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildFormField(_codeControllerForAdd, 'Mã bộ môn: *', 'Nhập mã bộ môn')),
                                  SizedBox(width: 16),
                                  Expanded(child: _buildFormField(_nameController, 'Tên bộ môn: *', 'Nhập tên bộ môn')),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildDepartmentDropdown( (newValue) { setDialogState(() => _selectedDepartment = newValue); }, _selectedDepartment),

                            ] else ... [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildFormField(_nameController, 'Tên bộ môn: *', 'Nhập tên bộ môn')),
                                  SizedBox(width: 16),
                                  Expanded(child: _buildDepartmentDropdown( (newValue) { setDialogState(() => _selectedDepartment = newValue); }, _selectedDepartment)),
                                ],
                              ),
                            ],
                            SizedBox(height: 16),
                            Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            TextFormField(
                              controller: _descController,
                              decoration: InputDecoration(
                                hintText: 'Nhập mô tả',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              maxLines: 4,
                              minLines: 3,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
              );
              return WillPopScope(
                onWillPop: _showExitConfirmationDialog,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  title: _buildDialogHeader(isEdit ? 'Chỉnh Sửa Thông Tin Bộ Môn' : 'Thêm Bộ Môn Mới'),
                  contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 500),
                    child: formContent,
                  ),
                  actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  actions: <Widget>[
                    OutlinedButton(
                      onPressed: _isSaving ? null : () async {
                        if (await _showExitConfirmationDialog()) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text('Hủy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cancelColor, side: BorderSide(color: cancelColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveDivision(() => setDialogState(() => _isSaving = !_isSaving)),
                      child: Text(isEdit ? 'Lưu' : 'Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              );
            }
        );
      },
    );
  }

  // (Hàm helper build Header cho Dialog)
  Widget _buildDialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      color: tluBlue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          )
        ],
      ),
    );
  }

  // (Hàm helper build Form Field)
  Widget _buildFormField(TextEditingController controller, String label, String hint, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: isReadOnly,
            fillColor: isReadOnly ? Colors.grey[100] : null,
          ),
          validator: (value) {
            if (!isReadOnly && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập thông tin';
            }
            return null;
          },
        ),
      ],
    );
  }

  // (Hàm helper build Dropdown Khoa)
  Widget _buildDepartmentDropdown(ValueChanged<Department?> onChanged, Department? currentValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Khoa: *', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        DropdownButtonFormField<Department>(
          value: currentValue,
          hint: Text('-- Chọn Khoa quản lý --'),
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: _departments.map((Department department) {
            return DropdownMenuItem<Department>(
              value: department,
              child: Text(department.name),
            );
          }).toList(),
          onChanged: _isLoadingDepartments ? null : onChanged,
          validator: (value) => value == null ? 'Vui lòng chọn khoa' : null,
        ),
      ],
    );
  }

  /// ---------------------------------------------------
  /// DIALOG XÓA BỘ MÔN (Pop-up)
  /// ---------------------------------------------------
  void _showDeleteConfirmationDialog(Division division) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isDeleting = false;
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                title: Center(child: Text('Thông báo!', style: TextStyle(fontWeight: FontWeight.bold))),
                content: Text('Bạn chắc chắn muốn xóa bộ môn "${division.name}"?', textAlign: TextAlign.center),
                actionsAlignment: MainAxisAlignment.center,
                actions: <Widget>[
                  OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                    child: Text('Hủy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cancelColor, side: BorderSide(color: cancelColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isDeleting ? null : () async {
                      setDialogState(() { _isDeleting = true; });
                      try {
                        await _apiService.deleteDivision(division.id);
                        if (!mounted) return;
                        _showSnackBar('Xóa bộ môn thành công!', isError: false);
                        Navigator.of(context).pop();
                        _refreshDivisionList(clearSearch: true); // (Sửa logic refresh)
                      } catch (e) {
                        if (!mounted) return;
                        _showSnackBar('Lỗi khi xóa: $e', isError: true);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // (Hàm helper SnackBar)
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

} // End of _DivisionScreenState