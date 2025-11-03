import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/registered_course.dart';
import '../models/class_course.dart';
import '../models/class_course_form_data.dart';

// Import model chi tiết (chứa class Student)
import '../models/class_course_detail.dart';

import '../models/division.dart';
import '../models/course.dart';
import '../models/department.dart';
import '../table/user.dart';
import '../models/room.dart';

// Extension để hỗ trợ firstOrNull
extension FirstOrNullExtension<E> on Iterable<E> {
  E? firstOrNull(bool Function(E) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

class RegisteredCourseScreen extends StatefulWidget {
  const RegisteredCourseScreen({Key? key}) : super(key: key);

  @override
  _RegisteredCourseScreenState createState() => _RegisteredCourseScreenState();
}

class _RegisteredCourseScreenState extends State<RegisteredCourseScreen> {
  // (Giữ nguyên code Màn hình chính...)
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // State
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  // State cho danh sách, tìm kiếm và phân trang
  List<RegisteredCourse> _allCourses = [];
  List<RegisteredCourse> _paginatedCourses = [];
  String _searchQuery = '';

  int _currentPage = 1;
  final int _rowsPerPage = 10;
  int _totalRows = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _apiService.fetchRegisteredCourses();
      setState(() {
        _allCourses = courses;
        _totalRows = _allCourses.length;
        _applyFiltersAndPagination();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndPagination() {
    List<RegisteredCourse> filteredCourses = _allCourses;

    if (_searchQuery.isNotEmpty) {
      filteredCourses = _allCourses.where((course) {
        final queryLower = _searchQuery.toLowerCase();
        return (course.classCode.toLowerCase().contains(queryLower) ||
            course.courseName.toLowerCase().contains(queryLower) ||
            course.teacherName.toLowerCase().contains(queryLower));
      }).toList();
    }

    _totalRows = filteredCourses.length;

    final int totalPages = (_totalRows / _rowsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    }
    if (_currentPage < 1) {
      _currentPage = 1;
    }

    final int startIndex = (_currentPage - 1) * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage).clamp(0, _totalRows);

    setState(() {
      _paginatedCourses = filteredCourses.sublist(startIndex, endIndex);
    });
  }

  void _onPageChanged(int newPage) {
    setState(() {
      _currentPage = newPage;
      _applyFiltersAndPagination();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _applyFiltersAndPagination();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)));
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
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
                onPressed: () => _showAddEditDialog(context),
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Đăng ký", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tluBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              ),
              Container(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm Mã HP, Tên HP, Giảng viên",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onChanged: _onSearchChanged,
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
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(tluBlue),
                    headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Tên lớp học phần')),
                      DataColumn(label: Text('Tên học phần')),
                      DataColumn(label: Text('Giảng viên')),
                      DataColumn(label: Text('Học kì')),
                      DataColumn(label: Text('Tổng số SV')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: List.generate(
                        _paginatedCourses.length,
                            (index) {
                          final course = _paginatedCourses[index];
                          final stt = (_currentPage - 1) * _rowsPerPage + index + 1;
                          return _buildDataRow(stt, course);
                        }
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  DataRow _buildDataRow(int stt, RegisteredCourse course) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(course.classCode)),
        DataCell(Text(course.courseName)),
        DataCell(Text(course.teacherName)),
        DataCell(Text(course.semester)),
        DataCell(Text(course.totalStudents.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                  icon: Icon(Icons.info_outline, color: iconView),
                  onPressed: () => _navigateToDetail(context, course.id),
                  tooltip: "Xem chi tiết"
              ),
              IconButton(
                  icon: Icon(Icons.edit_outlined, color: iconEdit),
                  onPressed: () => _showAddEditDialog(context, course: course),
                  tooltip: "Sửa"
              ),
              IconButton(
                  icon: Icon(Icons.delete_outline, color: iconDelete),
                  onPressed: () => _showDeleteConfirmDialog(context, course),
                  tooltip: "Xóa"
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final int totalPages = (_totalRows / _rowsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text("Trang $_currentPage / $totalPages (Tổng: $_totalRows)"),
        ),

        Row(
          children: [
            IconButton(
              icon: Icon(Icons.first_page),
              onPressed: _currentPage == 1 ? null : () => _onPageChanged(1),
            ),
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: _currentPage == 1 ? null : () => _onPageChanged(_currentPage - 1),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: _currentPage == totalPages ? null : () => _onPageChanged(_currentPage + 1),
            ),
            IconButton(
              icon: Icon(Icons.last_page),
              onPressed: _currentPage == totalPages ? null : () => _onPageChanged(totalPages),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, int courseId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CourseDetailDialog(
          apiService: _apiService,
          courseId: courseId,
        );
      },
    );
  }

  void _showAddEditDialog(BuildContext context, {RegisteredCourse? course}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _AddEditRegisteredCourseDialog(
          apiService: _apiService,
          course: course,
          onSave: () {
            Navigator.of(dialogContext).pop();
            _loadCourses();
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, RegisteredCourse course) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {

        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Thông báo!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                  IconButton(
                    onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              content: Text("Bạn chắc chắn muốn xóa lớp học phần\n'${course.courseName}' (${course.classCode})?"),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              actions: [
                OutlinedButton(
                  onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text("Hủy", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    minimumSize: Size(110, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : () async {

                    dialogSetState(() {
                      isDeleting = true;
                    });

                    try {
                      await _apiService.deleteClassCourse(course.id);

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();
                      _loadCourses();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xóa thành công!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Xóa thất bại: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: isDeleting
                      ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : Text("Xác nhận", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(110, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ===================================================================
// DIALOG THÊM/SỬA
// ===================================================================
class _AddEditRegisteredCourseDialog extends StatefulWidget {
  final ApiService apiService;
  final RegisteredCourse? course;
  final VoidCallback onSave;

  const _AddEditRegisteredCourseDialog({
    required this.apiService,
    this.course,
    required this.onSave,
  });

  @override
  _AddEditRegisteredCourseDialogState createState() =>
      _AddEditRegisteredCourseDialogState();
}

class _AddEditRegisteredCourseDialogState
    extends State<_AddEditRegisteredCourseDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = true;

  late Future<void> _loadFuture;
  ClassCourseFormData? _formData;

  // Biến state cho form
  String? _selectedSemester;
  int? _selectedCourseId;
  int? _selectedTeacherId;
  int? _selectedDepartmentId;
  int? _selectedDivisionId;
  int? _selectedRoomId;

  // ✅ SỬA LỖI: Thêm state cho lỗi server
  String? _serverError;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadFuture = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final formData = await widget.apiService.fetchClassCourseFormData();
      _formData = formData;

      if (widget.course != null) {
        final detail = await widget.apiService.fetchClassCourseDetails(widget.course!.id)
        as ClassCourseDetail;

        _nameController.text = detail.classCourse.name;
        _selectedSemester = detail.classCourse.semester;

        final courseMatch = formData.courses.firstOrNull((c) => c.name == detail.classCourse.courseName);
        if (courseMatch != null) _selectedCourseId = courseMatch.id;

        final teacherMatch = formData.teachers.firstOrNull((t) => t.name == detail.classCourse.teacherName);
        if (teacherMatch != null) _selectedTeacherId = teacherMatch.id;

        final deptMatch = formData.departments.firstOrNull((d) => d.name == detail.classCourse.departmentName);
        if (deptMatch != null) _selectedDepartmentId = deptMatch.id;

        final divMatch = formData.divisions.firstOrNull((d) => d.name == detail.classCourse.divisionName);
        if (divMatch != null) _selectedDivisionId = divMatch.id;

        final roomName = detail.classCourse.roomName;
        if (roomName != 'N/A') {
          final roomMatch = formData.rooms.firstOrNull((r) => r.name == roomName);
          if (roomMatch != null) _selectedRoomId = roomMatch.id;
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu form: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ✅ SỬA LỖI: Thêm tham số onChanged cho _buildTextField
  Widget _buildTextField(String label, String hintText, {
    bool isRequired = false,
    required TextEditingController controller,
    Function(String)? onChanged, // Thêm tham số này
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (isRequired ? " *" : ""), style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged, // Gán vào đây
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String hintText, {
    required List<DropdownMenuItem<dynamic>> items,
    dynamic value,
    required Function(dynamic) onChanged,
    bool isRequired = false,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label + (isRequired ? " *" : ""), style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: isEnabled ? Colors.white : Colors.grey[200],
          ),
          hint: Text(hintText),
          value: value,
          items: items,
          onChanged: isEnabled ? (val) => onChanged(val) : null,
          validator: (value) {
            if (isRequired && value == null) {
              return 'Vui lòng chọn $label';
            }
            return null;
          },
          isExpanded: true,
        ),
      ],
    );
  }

  // ✅ SỬA LỖI: Cập nhật _submitForm
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _serverError = null; // Xóa lỗi cũ khi submit
      });

      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'semester': _selectedSemester,
        'course_id': _selectedCourseId,
        'teacher_id': _selectedTeacherId,
        'department_id': _selectedDepartmentId,
        'division_id': _selectedDivisionId,
        'room_id': _selectedRoomId,
      };

      try {
        if (widget.course == null) {
          await widget.apiService.createClassCourse(data);
        } else {
          await widget.apiService.updateClassCourse(widget.course!.id, data);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.course == null ? 'Đã thêm thành công!' : 'Đã cập nhật thành công!'), backgroundColor: Colors.green),
        );
        widget.onSave(); // Đóng dialog và tải lại

      } catch (e) {
        // Lấy thông báo lỗi sạch (ví dụ: "Tên lớp học phần đã tồn tại...")
        String errorMessage = e.toString().replaceAll("Exception: ", "");

        if (mounted) {
          // THAY VÌ SNACKBAR, SET LỖI VÀO STATE
          setState(() {
            _serverError = errorMessage;
          });
        }
      } finally {
        // Chỉ reset loading, không đóng dialog nếu có lỗi
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  // ✅ SỬA LỖI: Thêm widget hiển thị lỗi
  Widget _buildServerErrorWidget() {
    if (_serverError == null) {
      return const SizedBox.shrink(); // Không có lỗi
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
      child: Text(
        _serverError!,
        style: TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }


  // Layout 2 cột (Dùng cho cả Thêm và Sửa)
  Widget _buildTwoColumnForm(ClassCourseFormData formData) {

    final allDivisions = formData.divisions;
    final allCourses = formData.courses;
    final allRooms = formData.rooms;

    final bool isDepartmentSelected = _selectedDepartmentId != null;

    String? selectedDeptName;
    if (isDepartmentSelected) {
      try {
        selectedDeptName = formData.departments.firstWhere((d) => d.id == _selectedDepartmentId).name;
      } catch (e) { /* không tìm thấy */ }
    }

    final List<Division> filteredDivisions = (isDepartmentSelected && selectedDeptName != null)
        ? allDivisions.where((d) => d.departmentName == selectedDeptName).toList()
        : <Division>[];
    final List<Course> filteredCourses = (isDepartmentSelected && selectedDeptName != null)
        ? allCourses.where((c) => c.departmentName == selectedDeptName).toList()
        : <Course>[];

    return Form(
        key: _formKey,
        child: Container(
          width: 600,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột Trái
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn lề cho text lỗi
                    children: [
                      _buildTextField("Tên lớp học phần", "Nhập Tên lớp học phần",
                        isRequired: true,
                        controller: _nameController,
                        // ✅ SỬA LỖI: Xóa lỗi khi người dùng nhập
                        onChanged: (value) {
                          if (_serverError != null) {
                            setState(() { _serverError = null; });
                          }
                        },
                      ),
                      _buildServerErrorWidget(), // Hiển thị lỗi dưới Tên LHP
                      SizedBox(height: 16),
                      _buildDropdownField("Bộ môn phụ trách",
                        isDepartmentSelected ? "Chọn bộ môn" : "Chọn khoa trước",
                        isRequired: true,
                        isEnabled: isDepartmentSelected,
                        value: _selectedDivisionId,
                        items: filteredDivisions.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                        onChanged: (value) => setState(() => _selectedDivisionId = value),
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField("Học phần",
                        isDepartmentSelected ? "Chọn học phần" : "Chọn khoa trước",
                        isRequired: true,
                        isEnabled: isDepartmentSelected,
                        value: _selectedCourseId,
                        items: filteredCourses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (value) => setState(() => _selectedCourseId = value),
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField("Phòng học",
                        "-- Chọn phòng học --",
                        isRequired: false,
                        value: _selectedRoomId,
                        items: allRooms.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                        onChanged: (value) => setState(() => _selectedRoomId = value),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 24),
                // Cột Phải
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn lề cho text lỗi
                    children: [
                      _buildDropdownField("Khoa phụ trách", "-- Chọn khoa --",
                        isRequired: true,
                        value: _selectedDepartmentId,
                        items: formData.departments.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                            _selectedDivisionId = null;
                            _selectedCourseId = null;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField("Giảng viên phụ trách", "-- Chọn giảng viên --",
                        isRequired: true,
                        value: _selectedTeacherId,
                        items: formData.teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (value) => setState(() => _selectedTeacherId = value),
                      ),
                      SizedBox(height: 16),
                      _buildDropdownField("Học kỳ", "-- Chọn học kỳ --",
                        isRequired: true,
                        value: _selectedSemester,
                        items: formData.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (value) {
                          // ✅ SỬA LỖI: Xóa lỗi khi người dùng chọn
                          if (_serverError != null) {
                            setState(() { _serverError = null; });
                          }
                          setState(() => _selectedSemester = value);
                        },
                      ),
                      _buildServerErrorWidget(), // Hiển thị lỗi dưới Học kỳ
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.course != null;
    final String title = isEditMode ? "CHỈNH SỬA ĐĂNG KÍ HỌC PHẦN" : "THÊM LỚP HỌC PHẦN MỚI";

    // Sử dụng FutureBuilder để đợi tải dữ liệu
    return FutureBuilder<void>(
        future: _loadFuture,
        builder: (context, snapshot) {

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            backgroundColor: Color(0xFFF4F7FC),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF005A9C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.all(24.0),
            // Dùng cờ _isLoading (được set trong _loadInitialData)
            content: _isLoading
                ? Container(
              width: 600,
              height: 200, // Chiều cao tạm thời cho loading
              child: Center(child: CircularProgressIndicator()),
            )
                : _buildTwoColumnForm(_formData!), // Hiển thị form khi _isLoading = false

            actionsPadding: const EdgeInsets.all(24.0),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: Text("Hủy", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  minimumSize: Size(120, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text("Xác nhận", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(120, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
            ],
          );
        }
    );
  }
}

// ===================================================================
// DIALOG CHI TIẾT
// ===================================================================
class _CourseDetailDialog extends StatefulWidget {
  final ApiService apiService;
  final int courseId;

  const _CourseDetailDialog({
    Key? key,
    required this.apiService,
    required this.courseId,
  }) : super(key: key);

  @override
  _CourseDetailDialogState createState() => _CourseDetailDialogState();
}

class _CourseDetailDialogState extends State<_CourseDetailDialog> {
  bool _isLoading = true;
  late Future<ClassCourseDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetails();
  }

  Future<ClassCourseDetail> _loadDetails() async {
    try {
      final detail = await widget.apiService.fetchClassCourseDetails(widget.courseId)
      as ClassCourseDetail;
      return detail;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            readOnly: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(List<Student> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Chi tiết sinh viên",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Color(0xFF005A9C)),
            headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            columns: const [
              DataColumn(label: Text('STT')),
              DataColumn(label: Text('Mã sinh viên')),
              DataColumn(label: Text('Họ tên SV')),
              DataColumn(label: Text('Lớp')),
            ],
            rows: List.generate(
              students.length,
                  (index) {
                final student = students[index];

                // Tách email để lấy MSV và Lớp
                String emailPrefix = student.email.split('@').first; // '65TDH1.huong.dt'
                String studentClass = "N/A";
                String studentId = emailPrefix; // Mặc định

                if (emailPrefix.contains('.')) {
                  var parts = emailPrefix.split('.');
                  if (parts.length > 1) {
                    studentClass = parts[0]; // '65TDH1'
                    // Gộp các phần còn lại làm mã sinh viên
                    studentId = parts.sublist(1).join('.'); // 'huong.dt'
                  }
                }

                return DataRow(
                  cells: [
                    DataCell(Text((index + 1).toString())),
                    DataCell(Text(studentId)), // Mã SV (huong.dt)
                    DataCell(Text(student.name)), // Họ tên
                    DataCell(Text(studentClass)), // Lớp (65TDH1)
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        width: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Sửa lỗi overflow
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF005A9C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "CHI TIẾT ĐĂNG KÍ HỌC PHẦN",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Sửa lỗi overflow bằng cách bọc nội dung có thể cuộn
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : FutureBuilder<ClassCourseDetail>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData) {
                    return Center(child: Text('Không tìm thấy chi tiết'));
                  }

                  final detail = snapshot.data!;
                  final courseInfo = detail.classCourse;
                  final students = detail.students;

                  // Lấy phòng từ ClassCourse (đã sửa)
                  final String roomName = courseInfo.roomName;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cột trái
                            Expanded(
                              child: Column(
                                children: [
                                  _buildInfoField("Giảng viên", courseInfo.teacherName),
                                  _buildInfoField("Học phần", courseInfo.courseName),
                                  _buildInfoField("Phòng", roomName), // <-- Hiển thị phòng
                                ],
                              ),
                            ),
                            SizedBox(width: 24),
                            // Cột phải
                            Expanded(
                              child: Column(
                                children: [
                                  _buildInfoField("Lớp học phần", "${courseInfo.courseName} (${courseInfo.name})"),
                                  _buildInfoField("Học kỳ", courseInfo.semester),
                                  _buildInfoField("Số sinh viên", students.length.toString()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Bảng sinh viên
                        _buildStudentsTable(students),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("Quay lại", style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF005A9C),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
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