// File: lib/screens/khoa_screen.dart
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/department.dart';
import '../models/department_detail.dart'; // (Import)
import '../table/user.dart';             // (Import)
import '../models/major.dart';
import '../models/division.dart';
import 'dart:async'; // Cho debounce
import 'package:collection/collection.dart'; // Cho firstWhereOrNull
import 'dart:math'; // Cho hàm min()

class KhoaScreen extends StatefulWidget {
  const KhoaScreen({Key? key}) : super(key: key);

  @override
  _KhoaScreenState createState() => _KhoaScreenState();
}

class _KhoaScreenState extends State<KhoaScreen> {
  // --- Màu sắc ---
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconViewColor = Colors.blue;
  final Color iconEditColor = Colors.green;
  final Color iconDeleteColor = Colors.red;
  final Color cancelColor = Colors.red;
  final Color confirmColor = Colors.green.shade600;

  final ApiService _apiService = ApiService();

  List<User> _teachers = [];
  bool _isLoadingTeachers = false;

  // --- State cho Phân trang và Tìm kiếm (FRONT-END) ---
  List<Department> _allDepartments = [];
  List<Department> _filteredDepartments = [];
  List<Department> _pagedDepartments = [];

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  final int _rowsPerPage = 10;
  bool _isLoading = true;
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

  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _isLoading = true; });

    try {
      final teachersFuture = _fetchTeachers();
      final departmentsFuture = _apiService.fetchDepartments();

      final results = await Future.wait([teachersFuture, departmentsFuture]);

      final teachers = results[0] as List<User>;
      final departments = results[1] as List<Department>;

      if (mounted) {
        setState(() {
          _teachers = teachers;
          _allDepartments = departments;
          _filteredDepartments = departments;
          _updatePagination(departments);
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

  Future<List<User>> _fetchTeachers() async {
    if (mounted) setState(() { _isLoadingTeachers = true; });
    try {
      // ⚠️ LƯU Ý: Bạn cần tạo hàm API 'fetchAllTeachers'
      // final teachers = await _apiService.fetchAllTeachers();

      // (Sửa mock data để khớp với model User thật từ 'table/user.dart')
      await Future.delayed(Duration(milliseconds: 100));
      final teachers = [
        User(id: 1, name: 'Nguyễn Văn A', firstName: 'Nguyễn Văn', lastName: 'A', email: 'a@tlu.edu.vn', status: 'active', role: 'teacher', phoneNumber: '0123456789'),
        User(id: 2, name: 'Trần Thị B', firstName: 'Trần Thị', lastName: 'B', email: 'b@tlu.edu.vn', status: 'active', role: 'teacher', phoneNumber: '0987654321'),
      ];

      if (mounted) setState(() { _isLoadingTeachers = false; });
      return teachers;
    } catch (e) {
      if (mounted) setState(() { _isLoadingTeachers = false; });
      _showSnackBar('Lỗi tải danh sách giảng viên: $e', isError: true);
      return [];
    }
  }

  void _refreshDepartmentList({bool clearSearch = false}) {
    if (clearSearch) {
      _currentSearchQuery = '';
      _searchController.clear();
    }
    _loadInitialData();
  }

  // --- Hàm xử lý Phân trang & Tìm kiếm (FRONT-END) ---
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _currentSearchQuery = _searchController.text;
      _filterAndPaginateList();
    });
  }

  void _filterAndPaginateList() {
    if (!mounted) return;
    setState(() {
      if (_currentSearchQuery.isEmpty) {
        _filteredDepartments = List.from(_allDepartments);
      } else {
        final query = _currentSearchQuery.toLowerCase();
        _filteredDepartments = _allDepartments.where((dept) {
          return dept.name.toLowerCase().contains(query) ||
              dept.code.toLowerCase().contains(query) ||
              dept.headTeacherName.toLowerCase().contains(query);
        }).toList();
      }
      _updatePagination(_filteredDepartments, goToFirstPage: true);
    });
  }

  void _updatePagination(List<Department> list, {bool goToFirstPage = false}) {
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

      int startIndex = (_currentPage - 1) * _rowsPerPage;
      int endIndex = min(startIndex + _rowsPerPage, _totalItems);

      _pagedDepartments = (startIndex < _totalItems)
          ? list.sublist(startIndex, endIndex)
          : [];
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    if (mounted) {
      setState(() {
        _currentPage = page;
        _updatePagination(_filteredDepartments);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context, _pagedDepartments);
  }

  Widget _buildContent(BuildContext context, List<Department> departmentsToDisplay) {
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
                onPressed: _isLoadingTeachers ? null : () => _showAddEditDepartmentDialog(null),
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm khoa", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    hintText: "Tìm kiếm theo tên, mã, trưởng khoa...",
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
                            DataColumn(label: Text('Mã khoa')),
                            DataColumn(label: Text('Tên khoa')),
                            DataColumn(label: Text('Trưởng khoa')),
                            DataColumn(label: Text('Số lượng GV')),
                            DataColumn(label: Text('Số lượng ngành')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: List.generate(
                            departmentsToDisplay.length,
                                (index) => _buildDataRow(index + 1 + (_currentPage - 1) * _rowsPerPage, departmentsToDisplay[index]),
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
          if (!_isLoading && departmentsToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(child: Text(_currentSearchQuery.isEmpty ? 'Chưa có khoa nào.' : 'Không tìm thấy kết quả.')),
            ),
        ],
      ),
    );
  }

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

  DataRow _buildDataRow(int stt, Department department) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(department.code)),
        DataCell(Text(department.name)),
        DataCell(Text(department.headTeacherName)),
        DataCell(Text(department.teacherCount.toString())),
        DataCell(Text(department.majorsCount.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconViewColor),
                onPressed: () => _showViewDepartmentDialog(department),
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEditColor),
                onPressed: _isLoadingTeachers ? null : () => _showAddEditDepartmentDialog(department),
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDeleteColor),
                onPressed: () => _showDeleteConfirmationDialog(department),
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ---------------------------------------------------
  /// DIALOG XEM CHI TIẾT KHOA (Pop-up)
  /// ---------------------------------------------------
  void _showViewDepartmentDialog(Department department) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.all(0),
          title: _buildDialogHeader('Thông Tin Khoa'),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: FutureBuilder<DepartmentDetail>(
              future: _apiService.fetchDepartmentDetails(department.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          "Lỗi tải chi tiết",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Không thể tải dữ liệu chi tiết cho khoa này.\nLỗi: ${snapshot.error}",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                if (snapshot.hasData) {
                  return _buildDetailContent(snapshot.data!);
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text("Không có dữ liệu."),
                  ),
                );
              },
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        );
      },
    );
  }

  Widget _buildDetailContent(DepartmentDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionTitle('Thông tin cơ bản'),
          _buildReadOnlyInfo(detail.department),
          Divider(height: 32),

          _buildSectionTitle('Danh sách giảng viên (${detail.teachers.length})'),
          _buildTeacherTable(detail.teachers),
          Divider(height: 32),

          _buildSectionTitle('Danh sách ngành (${detail.majors.length})'),
          _buildMajorList(detail.majors),
          Divider(height: 32),

          _buildSectionTitle('Danh sách bộ môn (${detail.divisions.length})'),
          _buildDivisionTable(detail.divisions),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue));
  }

  Widget _buildReadOnlyInfo(Department dept) {
    return Column(
      children: [
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyField("Mã khoa:", dept.code)),
            SizedBox(width: 16),
            Expanded(child: _buildReadOnlyField("Tên khoa:", dept.name)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyField("Số lượng giảng viên:", dept.teacherCount.toString())),
            SizedBox(width: 16),
            Expanded(child: _buildReadOnlyField("Số lượng ngành:", dept.majorsCount.toString())),
          ],
        ),
        SizedBox(height: 16),
        _buildReadOnlyField("Mô tả:", dept.description ?? 'Chưa có mô tả', isMultiLine: true),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, {bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(minHeight: isMultiLine ? 80 : 40),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value.isNotEmpty ? value : '(trống)'),
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
          DataColumn(label: Text('Mã GV')),
          DataColumn(label: Text('Họ tên')),
          DataColumn(label: Text('Email')),
        ],
        rows: List.generate(teachers.length, (index) {
          final teacher = teachers[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            // 👇 **** SỬA LỖI teacher.code **** 👇
            DataCell(Text('GV${teacher.id.toString().padLeft(3,'0')}')),
            // 👆 **** KẾT THÚC SỬA LỖI **** 👆
            DataCell(Text(teacher.name)),
            DataCell(Text(teacher.email)),
          ]);
        }),
      ),
    );
  }

  Widget _buildMajorList(List<Major> majors) {
    if (majors.isEmpty) return Text('Không có ngành học.');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: majors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(majors[index].name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(majors[index].code ?? 'N/A'),
          );
        },
        separatorBuilder: (context, index) => Divider(height: 1),
      ),
    );
  }

  Widget _buildDivisionTable(List<Division> divisions) {
    if (divisions.isEmpty) return Text('Không có bộ môn.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('STT')),
          DataColumn(label: Text('Mã BM')),
          DataColumn(label: Text('Tên bộ môn')),
        ],
        rows: List.generate(divisions.length, (index) {
          final division = divisions[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text(division.code)),
            DataCell(Text(division.name)),
          ]);
        }),
      ),
    );
  }


  /// ---------------------------------------------------
  /// DIALOG THÊM / CHỈNH SỬA KHOA (Pop-up)
  /// ---------------------------------------------------
  void _showAddEditDepartmentDialog(Department? department) {
    final bool isEdit = department != null;
    final _formKey = GlobalKey<FormState>();

    final _nameController = TextEditingController(text: isEdit ? department?.name ?? '' : '');
    final _codeController = TextEditingController(text: isEdit ? department?.code ?? '' : '');
    final _descController = TextEditingController(text: isEdit ? department?.description ?? '' : '');

    User? _selectedTeacher;

    if (isEdit) {
      _selectedTeacher = _teachers.firstWhereOrNull(
              (t) => t.id == department?.headId
      );
    }

    bool _isSaving = false;

    Future<void> _saveDepartment(VoidCallback onSavingStateChange) async {
      if (_formKey.currentState!.validate()) {
        onSavingStateChange();
        final data = {
          'name': _nameController.text,
          'code': _codeController.text,
          'head_id': _selectedTeacher?.id,
          'description': _descController.text,
        };

        try {
          if (isEdit) {
            await _apiService.updateDepartment(department!.id, data);
          } else {
            await _apiService.createDepartment(data);
          }
          if (!mounted) return;
          _showSnackBar(isEdit ? 'Cập nhật khoa thành công!' : 'Thêm khoa thành công!', isError: false);
          Navigator.of(context).pop();
          _refreshDepartmentList(clearSearch: !isEdit);
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
          content: Text(isEdit ? 'Bạn có muốn thoát khỏi chức năng sửa thông tin?' : 'Bạn có muốn thoát khỏi chức năng thêm mới?', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy'),
              style: OutlinedButton.styleFrom(foregroundColor: cancelColor, side: BorderSide(color: cancelColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Xác nhận'),
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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

              Widget formContent = Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildFormField(_codeController, 'Mã khoa: *', 'Nhập mã khoa')),
                          SizedBox(width: 16),
                          Expanded(child: _buildFormField(_nameController, 'Tên khoa: *', 'Nhập tên khoa')),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildTeacherDropdown( (newValue) { setDialogState(() => _selectedTeacher = newValue); }, _selectedTeacher),
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

              return WillPopScope(
                onWillPop: _showExitConfirmationDialog,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  title: _buildDialogHeader(isEdit ? 'Chỉnh Sửa Thông Tin Khoa' : 'Thêm Khoa Mới'),
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
                      style: OutlinedButton.styleFrom(foregroundColor: cancelColor, side: BorderSide(color: cancelColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveDepartment(() => setDialogState(() => _isSaving = !_isSaving)),
                      child: Text(isEdit ? 'Lưu' : 'Xác nhận'),
                      style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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

  Widget _buildTeacherDropdown(ValueChanged<User?> onChanged, User? currentValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trưởng khoa: *', style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        DropdownButtonFormField<User>(
          value: currentValue,
          hint: Text('-- Chọn Trưởng khoa --'),
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          items: _teachers.map((User teacher) {
            return DropdownMenuItem<User>(
              value: teacher,
              child: Text(teacher.name), // (Model User có 'name' getter)
            );
          }).toList(),
          onChanged: _isLoadingTeachers ? null : onChanged,
          validator: (value) => value == null ? 'Vui lòng chọn trưởng khoa' : null,
        ),
      ],
    );
  }

  /// ---------------------------------------------------
  /// DIALOG XÓA KHOA (Pop-up)
  /// ---------------------------------------------------
  void _showDeleteConfirmationDialog(Department department) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isDeleting = false;
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                title: Center(child: Text('Thông báo!', style: TextStyle(fontWeight: FontWeight.bold))),
                content: Text('Bạn chắc chắn muốn xóa khoa "${department.name}"?', textAlign: TextAlign.center),
                actionsAlignment: MainAxisAlignment.center,
                actions: <Widget>[
                  OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                    child: Text('Hủy'),
                    style: OutlinedButton.styleFrom(foregroundColor: cancelColor, side: BorderSide(color: cancelColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isDeleting ? null : () async {
                      setDialogState(() { _isDeleting = true; });
                      try {
                        await _apiService.deleteDepartment(department.id);
                        if (!mounted) return;
                        _showSnackBar('Xóa khoa thành công!', isError: false);
                        Navigator.of(context).pop();
                        _refreshDepartmentList(clearSearch: true);
                      } catch (e) {
                        if (!mounted) return;
                        _showSnackBar('Lỗi khi xóa: $e', isError: true);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              );
            }
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

} // End of _KhoaScreenState
