import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/class_course.dart';
import '../models/class_course_detail.dart';
import '../table/user.dart';
import '../models/schedule.dart';
import '../models/course.dart';
import '../models/class_model.dart';
import '../models/department.dart';
import '../models/division.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:math';

class LopHocPhanScreen extends StatefulWidget {
  const LopHocPhanScreen({Key? key}) : super(key: key);

  @override
  _LopHocPhanScreenState createState() => _LopHocPhanScreenState();
}

// ✅ SỬA LỖI: Thêm extension firstOrNull nếu nó chưa có
// (Nếu bạn đã có ở tệp khác, có thể xóa đi,
// nhưng code của _SaveClassCourseFormState CẦN nó)
extension FirstOrNullExtension<E> on Iterable<E> {
  E? firstOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}


class _LopHocPhanScreenState extends State<LopHocPhanScreen> {
  // (Giữ nguyên toàn bộ code của _LopHocPhanScreenState
  // ... initState, dispose, loadInitialData, build, v.v...
  // ... _showViewDialog, _showAddEditDialog, _showDeleteDialog ...
  // --- Màu sắc ---
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconViewColor = Colors.blue;
  final Color iconEditColor = Colors.green;
  final Color iconDeleteColor = Colors.red;
  final Color cancelColor = Colors.red;
  final Color confirmColor = Colors.green.shade600;

  final ApiService _apiService = ApiService();

  // --- State cho Dữ liệu Form Dropdown ---
  List<User> _teachers = [];
  List<Course> _courses = [];
  List<Department> _departments = [];
  List<Division> _divisions = [];
  List<String> _semesters = [];
  bool _isLoadingFormData = false;

  // --- State cho Phân trang và Tìm kiếm (FRONT-END) ---
  List<ClassCourse> _allClassCourses = [];
  List<ClassCourse> _filteredClassCourses = [];
  List<ClassCourse> _pagedClassCourses = [];

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
    _fetchFormData();
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
      final classCourses = await _apiService.fetchClassCourses();

      if (mounted) {
        setState(() {
          _allClassCourses = classCourses;
          _filteredClassCourses = classCourses;
          _updatePagination(classCourses);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi tải dữ liệu lớp học phần: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _fetchFormData() async {
    if (mounted) setState(() { _isLoadingFormData = true; });
    try {
      final formData = await _apiService.fetchClassCourseFormData();

      if (mounted) {
        setState(() {
          _teachers = formData.teachers;
          _courses = formData.courses;
          _departments = formData.departments;
          _divisions = formData.divisions;
          _semesters = formData.semesters;
          _isLoadingFormData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingFormData = false; });
      _showSnackBar('Lỗi tải dữ liệu form: $e', isError: true);
    }
  }

  void _refreshClassCourseList({bool clearSearch = false}) {
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
        _filteredClassCourses = List.from(_allClassCourses);
      } else {
        final query = _currentSearchQuery.toLowerCase();
        _filteredClassCourses = _allClassCourses.where((cc) {
          // Sửa điều kiện tìm kiếm
          return cc.name.toLowerCase().contains(query) ||
              cc.teacherName.toLowerCase().contains(query) ||
              cc.departmentName.toLowerCase().contains(query) ||
              cc.courseName.toLowerCase().contains(query) ||
              cc.semester.toLowerCase().contains(query);
        }).toList();
      }
      _updatePagination(_filteredClassCourses, goToFirstPage: true);
    });
  }

  void _updatePagination(List<ClassCourse> list, {bool goToFirstPage = false}) {
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

      _pagedClassCourses = (startIndex < _totalItems)
          ? list.sublist(startIndex, endIndex)
          : [];
    });
  }

  void _goToPage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    if (mounted) {
      setState(() {
        _currentPage = page;
        _updatePagination(_filteredClassCourses);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context, _pagedClassCourses);
  }

  Widget _buildContent(BuildContext context, List<ClassCourse> coursesToDisplay) {
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
                // Vô hiệu hóa nút khi data form đang tải
                onPressed: _isLoadingFormData ? null : () => _showAddEditDialog(null),
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm lớp học phần", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    hintText: "Tìm kiếm theo tên, giảng viên, học phần...",
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
                          // Sửa Cột
                          columns: const [
                            DataColumn(label: Text('STT')),
                            DataColumn(label: Text('Tên lớp học phần')),
                            DataColumn(label: Text('Giảng viên phụ trách')),
                            DataColumn(label: Text('Khoa')),
                            DataColumn(label: Text('Học phần')),
                            DataColumn(label: Text('Học kỳ')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: List.generate(
                            coursesToDisplay.length,
                                (index) => _buildDataRow(index + 1 + (_currentPage - 1) * _rowsPerPage, coursesToDisplay[index]),
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
          if (!_isLoading && coursesToDisplay.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Center(child: Text(_currentSearchQuery.isEmpty ? 'Chưa có lớp học phần nào.' : 'Không tìm thấy kết quả.')),
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
              IconButton(icon: Icon(Icons.first_page), onPressed: _currentPage > 1 ? () => _goToPage(1) : null),
              IconButton(icon: Icon(Icons.navigate_before), onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null),
              SizedBox(width: 16),
              IconButton(icon: Icon(Icons.navigate_next), onPressed: _currentPage < _lastPage ? () => _goToPage(_currentPage + 1) : null),
              IconButton(icon: Icon(Icons.last_page), onPressed: _currentPage < _lastPage ? () => _goToPage(_lastPage) : null),
            ],
          ),
        ],
      ),
    );
  }

  // Sửa DataRow
  DataRow _buildDataRow(int stt, ClassCourse classCourse) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(classCourse.name)),
        DataCell(Text(classCourse.teacherName)),
        DataCell(Text(classCourse.departmentName)),
        DataCell(Text(classCourse.courseName)),
        DataCell(Text(classCourse.semester)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconViewColor),
                onPressed: () => _showViewDialog(classCourse),
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEditColor),
                onPressed: _isLoadingFormData ? null : () => _showAddEditDialog(classCourse),
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDeleteColor),
                onPressed: () => _showDeleteDialog(classCourse),
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ---------------------------------------------------
  /// DIALOG XEM CHI TIẾT (Pop-up)
  /// ---------------------------------------------------
  void _showViewDialog(ClassCourse classCourse) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.all(0),
          title: _buildDialogHeader('Thông Tin Lớp Học Phẩn'),
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            // Dùng FutureBuilder
            child: FutureBuilder<ClassCourseDetail>(
              future: _apiService.fetchClassCourseDetails(classCourse.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Lỗi tải chi tiết: ${snapshot.error}")));
                }
                if (snapshot.hasData) {
                  // Hiển thị nội dung chi tiết
                  return _buildDetailContent(snapshot.data!);
                }
                return Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("Không có dữ liệu.")));
              },
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Quay lại'),
              style: ElevatedButton.styleFrom(backgroundColor: tluBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        );
      },
    );
  }

  // NỘI DUNG CHI TIẾT
  Widget _buildDetailContent(ClassCourseDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionTitle('Thông tin cơ bản'),
          _buildReadOnlyInfo(detail.classCourse), // Hiển thị thông tin lớp
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue));
  }

  // Hiển thị thông tin cơ bản của ClassCourse
  Widget _buildReadOnlyInfo(ClassCourse cc) {
    return Column(
      children: [
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyField("Tên lớp học phần:", cc.name)),
            SizedBox(width: 16),
            Expanded(child: _buildReadOnlyField("Học kỳ:", cc.semester)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyField("Học phần:", cc.courseName)),
            SizedBox(width: 16),
            Expanded(child: _buildReadOnlyField("Khoa:", cc.departmentName)),
          ],
        ),
        SizedBox(height: 16),
        _buildReadOnlyField("Bộ môn:", cc.divisionName),
        SizedBox(height: 16),
        _buildReadOnlyField("Giảng viên:", cc.teacherName),
      ],
    );
  }

  // (Các hàm _buildScheduleTable và _buildStudentTable vẫn còn đây nhưng không được gọi)
  Widget _buildScheduleTable(List<Schedule> schedules) {
    if (schedules.isEmpty) return Text('Không có lịch học.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('STT')),
          DataColumn(label: Text('Phòng')),
          DataColumn(label: Text('Học kỳ')),
          DataColumn(label: Text('Tên học phần')),
        ],
        rows: List.generate(schedules.length, (index) {
          final s = schedules[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text(s.roomName)),
            DataCell(Text(s.semester)),
            DataCell(Text(s.courseName)),
          ]);
        }),
      ),
    );
  }
  Widget _buildStudentTable(List<User> students) {
    if (students.isEmpty) return Text('Không có sinh viên.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('STT')),
          DataColumn(label: Text('Mã SV')),
          DataColumn(label: Text('Họ tên')),
          DataColumn(label: Text('Email')),
        ],
        rows: List.generate(students.length, (index) {
          final student = students[index];
          return DataRow(cells: [
            DataCell(Text((index + 1).toString())),
            DataCell(Text('SV${student.id.toString().padLeft(3,'0')}')), // Mã SV giả định
            DataCell(Text(student.name)),
            DataCell(Text(student.email)),
          ]);
        }),
      ),
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
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.grey.shade300)),
          child: Text(value.isNotEmpty ? value : '(trống)'),
        ),
      ],
    );
  }


  /// ---------------------------------------------------
  /// DIALOG THÊM / CHỈNH SỬA (Pop-up)
  /// ---------------------------------------------------
  void _showAddEditDialog(ClassCourse? classCourse) {
    // Tải dữ liệu form NẾU chưa có
    if (_teachers.isEmpty && !_isLoadingFormData) {
      _fetchFormData();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _SaveClassCourseForm(
          classCourse: classCourse,
          onSave: (data) => _saveForm(classCourse, data),
          teachers: _teachers,
          courses: _courses,
          departments: _departments,
          divisions: _divisions,
          semesters: _semesters,
          isLoading: _isLoadingFormData,
        );
      },
    );
  }

  Future<void> _saveForm(ClassCourse? classCourse, Map<String, dynamic> data) async {
    final bool isEdit = classCourse != null;
    try {
      if (isEdit) {
        await _apiService.updateClassCourse(classCourse!.id, data);
      } else {
        await _apiService.createClassCourse(data);
      }
      if (!mounted) return;
      _showSnackBar(isEdit ? 'Cập nhật thành công!' : 'Thêm thành công!', isError: false);
      Navigator.of(context).pop(); // Đóng dialog
      _refreshClassCourseList(clearSearch: !isEdit);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi: $e', isError: true);
      rethrow;
    }
  }


  // (Helper từ KhoaScreen, giữ nguyên)
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

  /// ---------------------------------------------------
  /// DIALOG XÓA (Pop-up)
  /// ---------------------------------------------------
  void _showDeleteDialog(ClassCourse classCourse) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool _isDeleting = false;
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                title: Center(child: Text('Thông báo!', style: TextStyle(fontWeight: FontWeight.bold))),
                content: Text('Bạn chắc chắn muốn xóa lớp học phần "${classCourse.name}"?', textAlign: TextAlign.center),
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
                        // Gọi API xóa
                        await _apiService.deleteClassCourse(classCourse.id);
                        if (!mounted) return;
                        _showSnackBar('Xóa thành công!', isError: false);
                        Navigator.of(context).pop();
                        _refreshClassCourseList(clearSearch: true);
                      } catch (e) {
                        if (!mounted) return;
                        _showSnackBar('Lỗi khi xóa: $e', isError: true);
                        Navigator.of(context).pop();
                      }
                    },
                    child: _isDeleting
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text('Xác nhận'),
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
} // End of _LopHocPhanScreenState

// ===================================================================
// == WIDGET FORM THÊM/SỬA (TÁCH RIÊNG ĐỂ QUẢN LÝ STATE) ==
// ===================================================================
class _SaveClassCourseForm extends StatefulWidget {
  final ClassCourse? classCourse;
  final Future<void> Function(Map<String, dynamic> data) onSave;
  final bool isLoading;
  // Truyền dữ liệu dropdown
  final List<User> teachers;
  final List<Course> courses;
  final List<Department> departments;
  final List<Division> divisions;
  final List<String> semesters;

  const _SaveClassCourseForm({
    Key? key,
    this.classCourse,
    required this.onSave,
    required this.isLoading,
    required this.teachers,
    required this.courses,
    required this.departments,
    required this.divisions,
    required this.semesters,
  }) : super(key: key);

  @override
  _SaveClassCourseFormState createState() => _SaveClassCourseFormState();
}

class _SaveClassCourseFormState extends State<_SaveClassCourseForm> {
  final _formKey = GlobalKey<FormState>();
  bool get isEdit => widget.classCourse != null;
  bool _isSaving = false;

  // --- Controllers & State ---
  late TextEditingController _nameController;
  Department? _selectedDepartment;
  Division? _selectedDivision;
  User? _selectedTeacher;
  Course? _selectedCourse;
  String? _selectedSemester;

  // Lọc danh sách con
  List<Division> _filteredDivisions = [];
  List<Course> _filteredCourses = [];


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: isEdit ? widget.classCourse?.name : '');

    // Gán giá trị ban đầu nếu là "Sửa"
    if (isEdit && widget.classCourse != null) {
      final cc = widget.classCourse!;

      // 1. Tìm các đối tượng cha
      _selectedDepartment = widget.departments.firstWhereOrNull((d) => d.name == cc.departmentName);
      _selectedTeacher = widget.teachers.firstWhereOrNull((t) => t.name == cc.teacherName);
      _selectedSemester = widget.semesters.firstWhereOrNull((s) => s == cc.semester);

      // 2. Lọc danh sách con DỰA TRÊN KHOA
      if (_selectedDepartment != null) {
        _filteredDivisions = widget.divisions.where((div) => div.departmentName == _selectedDepartment!.name).toList();
        _filteredCourses = widget.courses.where((c) => c.departmentName == _selectedDepartment!.name).toList();
      } else {
        _filteredDivisions = widget.divisions;
        _filteredCourses = widget.courses;
      }

      // 3. Tìm đối tượng con TỪ DANH SÁCH ĐÃ LỌC
      _selectedDivision = _filteredDivisions.firstWhereOrNull((d) => d.name == cc.divisionName);
      _selectedCourse = _filteredCourses.firstWhereOrNull((c) => c.name == cc.courseName);

    }
  }

  // Hàm Cập nhật Lọc khi Khoa thay đổi
  void _onDepartmentChanged(Department? newDepartment) {
    setState(() {
      _selectedDepartment = newDepartment;
      // Reset các trường con
      _selectedDivision = null;
      _selectedCourse = null;
      _filteredDivisions = [];
      _filteredCourses = [];

      if (newDepartment != null) {
        // Lọc lại danh sách Bộ môn và Học phần
        _filteredDivisions = widget.divisions.where((div) => div.departmentName == newDepartment.name).toList();
        _filteredCourses = widget.courses.where((c) => c.departmentName == newDepartment.name).toList();
      }
    });
  }

  // ✅ SỬA LỖI: Xóa hàm này (để dùng pop() mặc định)
  // Future<bool> _showExitConfirmationDialog() async { ... }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final data = {
        'name': _nameController.text, // Tên lớp học phần
        'department_id': _selectedDepartment?.id,
        'division_id': _selectedDivision?.id,
        'course_id': _selectedCourse?.id,
        'teacher_id': _selectedTeacher?.id,
        'semester': _selectedSemester,
      };

      try {
        await widget.onSave(data);
      } catch (e) {
        // Lỗi đã được hiển thị bởi _saveForm
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = isEdit ? 'CHỈNH SỬA THÔNG TIN LỚP HỌC PHẦN' : 'THÊM LỚP HỌC PHẦN MỚI';
    final Color tluBlue = const Color(0xFF005A9C);

    // ✅ SỬA LỖI: Xóa WillPopScope
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        width: 800, // Form rộng
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tluBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.0),
                    topRight: Radius.circular(12.0),
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
                      // ✅ SỬA LỖI: Chỉ cần gọi pop()
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Nội dung Form
              widget.isLoading
                  ? Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cột trái
                    Expanded(
                      child: Column(
                        children: [
                          _buildTextField("Tên lớp học phần:", _nameController),
                          SizedBox(height: 16),
                          _buildDropdown<Division>("Bộ môn phụ trách:", _filteredDivisions, _selectedDivision,
                                  (val) => setState(() => _selectedDivision = val), (item) => item.name, "Chọn khoa trước"),
                          SizedBox(height: 16),
                          _buildDropdown<Course>("Học phần:", _filteredCourses, _selectedCourse,
                                  (val) => setState(() => _selectedCourse = val), (item) => item.name, "Chọn khoa trước"),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    // Cột phải
                    Expanded(
                      child: Column(
                        children: [
                          _buildDropdown<Department>("Khoa phụ trách:", widget.departments, _selectedDepartment,
                              _onDepartmentChanged, (item) => item.name, "-- Chọn khoa --"),
                          SizedBox(height: 16),
                          _buildDropdown<User>("Giảng viên phụ trách:", widget.teachers, _selectedTeacher,
                                  (val) => setState(() => _selectedTeacher = val), (item) => item.name, "-- Chọn giảng viên --"),
                          SizedBox(height: 16),
                          _buildDropdown<String>("Học kỳ:", widget.semesters, _selectedSemester,
                                  (val) => setState(() => _selectedSemester = val), (item) => item, "-- Chọn học kỳ --"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Nút bấm
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      // ✅ SỬA LỖI: Chỉ cần gọi pop()
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text("Hủy", style: TextStyle(color: Colors.red)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving || widget.isLoading ? null : _handleSubmit,
                      child: _isSaving
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : Text("Xác nhận", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label, // Ví dụ: "Tên lớp học phần:"
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            children: [
              TextSpan(
                text: " *", // Thêm dấu *
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Nhập $label",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập $label' : null,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>(String label, List<T> options, T? selectedValue, Function(T?) onChanged, String Function(T) getItemName, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label, // Ví dụ: "Khoa phụ trách:"
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            children: [
              TextSpan(
                text: " *", // Thêm dấu *
                style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: selectedValue,
          hint: Text(options.isEmpty ? hint : (hint.contains("--") ? hint : "-- Chọn --")),
          isExpanded: true,
          items: options.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(getItemName(item), overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: options.isEmpty ? null : onChanged,
          validator: (value) => (value == null) ? 'Vui lòng chọn $label' : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            disabledBorder: options.isEmpty ? OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)) : null,
          ),
        ),
      ],
    );
  }
}