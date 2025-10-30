import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/division.dart';
import '../models/department.dart'; // Import Department để dùng trong Dropdown
import '../models/course.dart';    // Import Course để xem chi tiết
import '../table/user.dart';       // Import User để xem chi tiết
import '../models/division_detail.dart'; // Import model chi tiết
import 'dart:async'; // Import để sử dụng Timer (cho debounce)
import 'package:collection/collection.dart'; // Import collection

class DivisionScreen extends StatefulWidget {
  const DivisionScreen({Key? key}) : super(key: key);

  @override
  _DivisionScreenState createState() => _DivisionScreenState();
}

class _DivisionScreenState extends State<DivisionScreen> {
  // --- Giữ nguyên các biến màu sắc, state, initState, dispose ---
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconViewColor = Colors.blue;
  final Color iconEditColor = Colors.green;
  final Color iconDeleteColor = Colors.red;
  final Color cancelColor = Colors.red;
  final Color confirmColor = Colors.green.shade600;

  // Xóa Future, thay bằng state
  // Future<List<Division>>? _divisionsFuture;
  final ApiService _apiService = ApiService();
  List<Department> _departments = [];
  bool _isLoadingDepartments = false;

  // --- State cho Phân trang và Tìm kiếm ---
  List<Division> _divisions = []; // Chỉ lưu danh sách của trang hiện tại
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  bool _isLoading = true; // Cờ loading chính
  String _currentSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Tải khoa và trang đầu tiên
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Hàm tải dữ liệu ban đầu (Khoa và Bộ môn trang 1)
  Future<void> _loadInitialData() async {
    await _fetchDepartments(); // Tải khoa trước
    await _fetchDivisions(page: 1, query: _currentSearchQuery); // Tải trang đầu tiên
  }

  // Hàm tải danh sách khoa
  Future<void> _fetchDepartments() async {
    if (_isLoadingDepartments) return;
    if (mounted) setState(() { _isLoadingDepartments = true; });
    try {
      _departments = await _apiService.fetchDepartments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách khoa: $e')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoadingDepartments = false; });
      }
    }
  }

  // --- HÀM MỚI: Tải dữ liệu bộ môn (có phân trang và tìm kiếm) ---
  Future<void> _fetchDivisions({required int page, required String query}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Bật loading
    });

    try {
      final paginatedData = await _apiService.fetchDivisions(page: page, query: query);
      if (mounted) {
        setState(() {
          _divisions = paginatedData.divisions; // Cập nhật danh sách
          _currentPage = paginatedData.currentPage;
          _lastPage = paginatedData.lastPage;
          _totalItems = paginatedData.totalItems;
          _isLoading = false; // Tắt loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; }); // Tắt loading dù lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách bộ môn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // --- KẾT THÚC HÀM MỚI ---

  // Hàm refresh (tải lại trang hiện tại hoặc về trang 1)
  void _refreshDivisionList({bool goToFirstPage = false}) {
    if (goToFirstPage) {
      // Khi Thêm mới, về trang 1 và xóa tìm kiếm
      _currentSearchQuery = '';
      _searchController.clear();
      _fetchDivisions(page: 1, query: '');
    } else {
      // Khi Sửa/Xóa, tải lại trang hiện tại
      _fetchDivisions(page: _currentPage, query: _currentSearchQuery);
    }
  }

  // --- Hàm xử lý khi nội dung ô tìm kiếm thay đổi ---
  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Khi tìm kiếm, luôn bắt đầu từ trang 1
      _currentSearchQuery = _searchController.text;
      _fetchDivisions(page: 1, query: _currentSearchQuery);
    });
  }
  // --- KẾT THÚC ---

  // (Xóa hàm _filterDivisions vì không còn dùng)

  @override
  Widget build(BuildContext context) {
    // Không dùng FutureBuilder nữa, chỉ dùng _buildContent
    return _buildContent(context, _divisions);
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
                    hintText: "Tìm kiếm theo tên, mã, khoa...", // Sửa hint text
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        }
                    )
                        : null,
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
              // Bọc trong AnimatedSwitcher để có hiệu ứng mờ khi tải
              return AnimatedCrossFade(
                duration: Duration(milliseconds: 300),
                // Hiển thị loading overlay
                firstChild: SizedBox(height: 400, child: Center(child: CircularProgressIndicator())), // Tăng chiều cao loading
                // Hiển thị bảng
                secondChild: Column( // Bọc Bảng và Nút Phân trang
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(tluBlue),
                          headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          // Xóa cột "Mã bộ môn" và "Số lượng MH"
                          columns: const [
                            DataColumn(label: Text('STT')),
                            // DataColumn(label: Text('Mã bộ môn')), // <-- Đã xóa
                            DataColumn(label: Text('Tên bộ môn')),
                            DataColumn(label: Text('Khoa')),
                            DataColumn(label: Text('Số lượng GV')),
                            // DataColumn(label: Text('Số lượng MH')), // <-- Đã xóa
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: List.generate(
                            divisionsToDisplay.length,
                            // Tính STT theo trang (10 mục/trang)
                                (index) => _buildDataRow(index + 1 + (_currentPage - 1) * 10, divisionsToDisplay[index]),
                          ),
                        ),
                      ),
                    ),
                    // 👇 THÊM BỘ ĐIỀU KHIỂN PHÂN TRANG 👇
                    if (_lastPage > 1) // Chỉ hiển thị nếu có nhiều hơn 1 trang
                      _buildPaginationControls(),
                    // 👆 KẾT THÚC PHÂN TRANG 👆
                  ],
                ),
                crossFadeState: _isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              );
            }),
          ),
          // Hiển thị thông báo nếu không có dữ liệu
          if (!_isLoading && divisionsToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(child: Text(_currentSearchQuery.isEmpty ? 'Chưa có bộ môn nào.' : 'Không tìm thấy kết quả.')),
            ),
        ],
      ),
    );
  }

  // --- BỘ ĐIỀU KHIỂN PHÂN TRANG MỚI ---
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
                onPressed: _currentPage > 1 ? () => _fetchDivisions(page: 1, query: _currentSearchQuery) : null,
                tooltip: 'Trang đầu',
              ),
              IconButton(
                icon: Icon(Icons.navigate_before),
                onPressed: _currentPage > 1 ? () => _fetchDivisions(page: _currentPage - 1, query: _currentSearchQuery) : null,
                tooltip: 'Trang trước',
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.navigate_next),
                onPressed: _currentPage < _lastPage ? () => _fetchDivisions(page: _currentPage + 1, query: _currentSearchQuery) : null,
                tooltip: 'Trang sau',
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: _currentPage < _lastPage ? () => _fetchDivisions(page: _lastPage, query: _currentSearchQuery) : null,
                tooltip: 'Trang cuối',
              ),
            ],
          ),
        ],
      ),
    );
  }
  // --- KẾT THÚC ---


  DataRow _buildDataRow(int stt, Division division) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        // DataCell(Text(division.code)), // <-- Đã xóa
        DataCell(Text(division.name)),
        DataCell(Text(division.departmentName)),
        DataCell(Text(division.teacherCount.toString())),
        // DataCell(Text(division.courseCount.toString())), // <-- Đã xóa
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

  /// Hiển thị Dialog Xem Chi Tiết Bộ Môn
  void _showViewDivisionDialog(Division division) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<DivisionDetail>(
          future: _apiService.fetchDivisionDetails(division.id),
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState == ConnectionState.waiting) {
              content = Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              content = Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Lỗi tải chi tiết: ${snapshot.error}")));
            } else if (snapshot.hasData) {
              final detail = snapshot.data!;
              content = SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Thông tin cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue)),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildReadOnlyField("Tên bộ môn:", detail.name)),
                        SizedBox(width: 16),
                        Expanded(child: _buildReadOnlyField("Khoa:", detail.departmentName)),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildReadOnlyField("Mô tả:", detail.description ?? 'Chưa có mô tả', isMultiLine: true),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildReadOnlyField("Số lượng giảng viên:", detail.teacherCount.toString())),
                        SizedBox(width: 16),
                        // Xóa Số lượng môn học
                        Expanded(child: Container()), // Placeholder
                      ],
                    ),
                    Divider(height: 32),
                    Text("Danh sách giảng viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue)),
                    SizedBox(height: 16),
                    _buildTeacherTable(detail.teachersList),
                    // Xóa Danh sách môn học
                  ],
                ),
              );
            } else {
              content = Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Không có dữ liệu chi tiết.")));
            }

            return AlertDialog(
              titlePadding: const EdgeInsets.all(0),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                color: tluBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Thông Tin Bộ Môn', style: TextStyle(color: Colors.white)),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    )
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.all(0),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: content,
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('Xác nhận'),
                  style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            );
          },
        );
      },
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
    if (teachers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Không có giảng viên nào thuộc bộ môn này.'),
      );
    }
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
            DataCell(Text(teacher.phoneNumber)),
          ]);
        }),
      ),
    );
  }

  // Xóa hàm _buildCourseTable
  // Widget _buildCourseTable(List<Course> courses) { ... }

  void _showAddEditDivisionDialog(Division? division) {
    final bool isEdit = division != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: isEdit ? division.name : '');
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Cập nhật bộ môn thành công!' : 'Thêm bộ môn thành công!'),
              backgroundColor: Colors.green, // <-- Thêm dòng này
            ),
          );
          Navigator.of(context).pop();
          _refreshDivisionList(goToFirstPage: !isEdit); // Về trang 1 nếu Thêm mới
        }catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
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
                            if (!isEdit) ...[ // Layout KHI THÊM MỚI
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

                            ] else ... [ // Layout KHI CHỈNH SỬA (Theo ảnh)
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
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    color: tluBlue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEdit ? 'Chỉnh Sửa Thông Tin Bộ Môn' : 'Thêm Bộ Môn Mới', style: TextStyle(color: Colors.white)),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () async {
                            if (await _showExitConfirmationDialog()) {
                              Navigator.of(context).pop();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        )
                      ],
                    ),
                  ),
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

  Widget _buildFormField(TextEditingController controller, String label, String hint, {bool isReadOnly = false}) {
    // --- Giữ nguyên ---
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

  Widget _buildDepartmentDropdown(ValueChanged<Department?> onChanged, Department? currentValue) {
    // --- Giữ nguyên ---
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

  void _showDeleteConfirmationDialog(Division division) {
    // --- Giữ nguyên ---
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Xóa bộ môn thành công!'),
                            backgroundColor: Colors.green, // Đảm bảo bạn gõ đúng 'backgroundColor'
                          ),
                        );
                        Navigator.of(context).pop();
                        _refreshDivisionList(goToFirstPage: true); // Về trang 1 sau khi xóa
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
                        );
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

} // End of _DivisionScreenState