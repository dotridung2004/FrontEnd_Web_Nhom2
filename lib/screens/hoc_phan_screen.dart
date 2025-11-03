import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import '../api_service.dart';
import '../models/course.dart';

// 👇 THÊM CÁC IMPORT NÀY CHO DIALOGS
import '../models/course_detail.dart';
import '../models/department.dart';
// 👆 KẾT THÚC THÊM IMPORT

// Hằng số màu
final Color tluBlue = const Color(0xFF005A9C);
final Color iconView = Colors.blue;
final Color iconEdit = Colors.green;
final Color iconDelete = Colors.red;

class HocPhanScreen extends StatefulWidget {
  const HocPhanScreen({Key? key}) : super(key: key);

  @override
  _HocPhanScreenState createState() => _HocPhanScreenState();
}

class _HocPhanScreenState extends State<HocPhanScreen> {
  // State cho API và Dữ liệu
  final ApiService _apiService = ApiService();
  late Future<List<Course>> _coursesFuture;
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];

  // State cho Tìm kiếm và Phân trang
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1; // Bắt đầu từ trang 1
  int _lastPage = 1;    // Lưu trữ tổng số trang
  int _totalItems = 0;  // Lưu trữ tổng số mục
  final int _rowsPerPage = 10; // Số hàng mỗi trang

  @override
  void initState() {
    super.initState();
    _refreshData(); // Tải dữ liệu lần đầu
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // === LOGIC TẢI VÀ LỌC DỮ LIỆU ===

  /// Tải lại dữ liệu mới nhất từ API (ĐÃ SỬA: Trả về Future<void> và dùng await)
  Future<void> _refreshData() async {
    _coursesFuture = _apiService.fetchCourses(); // Gọi API

    // THÊM: Dùng await để chờ Future hoàn thành trước khi tiếp tục
    await _coursesFuture.then((data) {
      if (mounted) {
        setState(() {
          _allCourses = data;
          _filterData(_searchController.text, resetPage: true); // Lọc theo query hiện tại
        });
      }
    }).catchError((e) {
      if (mounted) { // Kiểm tra xem widget còn tồn tại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  /// Lọc danh sách học phần dựa trên thanh tìm kiếm
  void _filterData(String query, {bool resetPage = false}) {
    List<Course> tempFilteredList;
    if (query.isEmpty) {
      tempFilteredList = List.from(_allCourses);
    } else {
      final lowerQuery = query.toLowerCase();
      tempFilteredList = _allCourses
          .where((course) =>
      course.name.toLowerCase().contains(lowerQuery) ||
          course.code.toLowerCase().contains(lowerQuery) ||
          course.departmentName.toLowerCase().contains(lowerQuery))
          .toList();
    }
    // CẬP NHẬT: Gọi hàm phân trang sau khi lọc
    _updatePagination(tempFilteredList, goToFirstPage: resetPage);
  }

  // THÊM: Hàm cập nhật trạng thái phân trang
  void _updatePagination(List<Course> list, {bool goToFirstPage = false}) {
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

      // Đảm bảo startIndex không âm
      int startIndex = (_currentPage - 1) * _rowsPerPage;
      int endIndex = min(startIndex + _rowsPerPage, _totalItems);

      // Lấy danh sách cho trang hiện tại
      _filteredCourses = (startIndex < _totalItems)
          ? list.sublist(startIndex, endIndex)
          : [];
    });
  }

  /// Lấy danh sách con cho trang hiện tại
  List<Course> _getDataForCurrentPage() {
    return _filteredCourses;
  }

  // THÊM: Hàm chuyển trang
  void _goToPage(int page) {
    if (page < 1 || page > _lastPage || page == _currentPage) return;
    if (mounted) {
      setState(() {
        _currentPage = page;
        // Kích hoạt lại bộ lọc/phân trang để cập nhật danh sách
        _filterData(_searchController.text, resetPage: false);
      });
    }
  }

  // === PHẦN BUILD UI ===

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Course>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        // Chỉ hiển thị loading khi chưa có dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allCourses.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        // Hiển thị lỗi chỉ khi không tải được lần đầu
        if (snapshot.hasError && _allCourses.isEmpty) {
          return Center(
            child: Text(
              'Lỗi khi tải dữ liệu: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        // Luôn build UI, kể cả khi đang refresh
        return _buildContent(context);
      },
    );
  }

  /// Widget chứa nội dung (Tiêu đề, Nút, Bảng, Phân trang)
  Widget _buildContent(BuildContext context) {
    final paginatedData = _getDataForCurrentPage();

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
              // Nút "Thêm học phần"
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(context), // GỌI DIALOG THÊM
                icon: Icon(Icons.add, color: Colors.white, size: 20),
                label: Text("Thêm học phần",
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

              // Thanh "Tìm kiếm"
              Container(
                width: 300,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm theo Mã,Tên học phần",
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
                  onChanged: (query) => _filterData(query, resetPage: true), // SỬA: Reset trang khi tìm kiếm
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Bảng Dữ liệu & Phân trang
          // SỬA: Gộp DataTable và Pagination Controls vào cùng một Container
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
                          DataColumn(label: Text('Mã học phần')),
                          DataColumn(label: Text('Tên học phần')),
                          DataColumn(label: Text('Số tín chỉ')),
                          DataColumn(label: Text('Khoa phụ trách')),
                          DataColumn(label: Text('Loại học phần')),
                          DataColumn(label: Text('Thao tác')),
                        ],
                        // Dùng dữ liệu đã phân trang
                        rows: List.generate(
                          paginatedData.length,
                              (index) {
                            final course = paginatedData[index];
                            final stt = (_currentPage - 1) * _rowsPerPage + index + 1; // TÍNH LẠI STT
                            return _buildDataRow(stt, course);
                          },
                        ),
                      ),
                    ),
                  );
                }),
                // 3. Phân trang
                if (_totalItems > 0)
                  _buildPaginationControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // THÊM: Widget điều khiển phân trang chi tiết
  Widget _buildPaginationControls() {
    return Container(
      // Padding chỉ nằm bên trong container
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        // Chỉ vẽ đường viền trên để phân tách với bảng dữ liệu
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // SỬA: Hiển thị thông tin phân trang giống mẫu
          Text('Trang $_currentPage / $_lastPage (Tổng: $_totalItems)'),
          Row(
            children: [
              // Nút trang đầu
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 20),
                onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                tooltip: 'Trang đầu',
              ),
              // Nút trang trước
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                tooltip: 'Trang trước',
              ),
              const SizedBox(width: 8),
              // Nút trang sau
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < _lastPage ? () => _goToPage(_currentPage + 1) : null,
                tooltip: 'Trang sau',
              ),
              // Nút trang cuối
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20),
                onPressed: _currentPage < _lastPage ? () => _goToPage(_lastPage) : null,
                tooltip: 'Trang cuối',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper để tạo một hàng dữ liệu (DataRow)
  DataRow _buildDataRow(int stt, Course course) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(course.code)),
        DataCell(Text(course.name)),
        DataCell(Text("${course.credits.toString()} Tín chỉ")),
        DataCell(Text(course.departmentName)),
        DataCell(Text(course.type)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconView),
                onPressed: () => _showViewDialog(context, course.id),
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEdit),
                onPressed: () => _showAddEditDialog(context, courseId: course.id),
                tooltip: "Sửa",
              ),
              IconButton(
                // SỬA: Thêm logic loading vào nút xóa
                icon: Icon(Icons.delete_outline, color: iconDelete),
                onPressed: () => _showDeleteDialog(context, course),
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === CÁC HÀM GỌI DIALOG ===

  /// Mở pop-up XEM chi tiết
  void _showViewDialog(BuildContext context, int courseId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Trả về widget ViewCourseDialog (định nghĩa ở dưới)
        return ViewCourseDialog(courseId: courseId);
      },
    );
  }

  /// Mở pop-up THÊM (nếu courseId=null) hoặc SỬA (nếu courseId có)
  void _showAddEditDialog(BuildContext context, {int? courseId}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // TRUYỀN HÀM _refreshData VÀO AddEditCourseDialog
        return AddEditCourseDialog(
          courseId: courseId,
          onRefresh: _refreshData, // <--- ĐÃ SỬA
        );
      },
    ).then((result) {
      // Sau khi dialog đóng, nếu nó trả về 'true' (nghĩa là đã lưu thành công)
      if (result == true) {
        // SnackBar thông báo thành công (Chỉ chạy sau khi refreshData đã hoàn thành)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(courseId == null ? 'Thêm học phần thành công!' : 'Cập nhật học phần thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // BỎ _refreshData() ở đây vì nó đã được gọi bên trong dialog
      }
    });
  }

  /// Mở pop-up XÓA
  void _showDeleteDialog(BuildContext context, Course course) {
    // Gọi hàm showDeleteConfirmationDialog (định nghĩa ở dưới)
    showDeleteConfirmationDialog(
      context,
      title: 'Thông báo!',
      content: 'Bạn chắc chắn muốn xóa học phần "${course.name}"?',
      // TRUYỀN HÀM API VÀ HÀM REFRESH VÀO ĐÂY
      onConfirmDelete: () => _apiService.deleteCourse(course.id).then((_) => _refreshData()), // <--- ĐÃ SỬA
    ).then((deleted) {
      // Nếu người dùng nhấn "Xác nhận" và quá trình xóa thành công (deleted = true)
      if (deleted == true) {
        // SnackBar thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã xóa học phần "${course.name}" thành công!'),
              backgroundColor: Colors.green),
        );
        // Không cần _refreshData() ở đây nữa
      } else if (deleted is Exception) {
        // Bắt lỗi nếu quá trình xóa thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi khi xóa: $deleted'), backgroundColor: Colors.red),
        );
      }
    });
  }
} // === KẾT THÚC CLASS _HocPhanScreenState ===

// =======================================================================
//
//               BẮT ĐẦU CODE CÁC DIALOG (POP-UP)
//
// =======================================================================

// ==========================================================
// 1. POPUP XEM CHI TIẾT (ĐÃ CĂN CHỈNH VÀ SỬA MÔ TẢ)
// ==========================================================
class ViewCourseDialog extends StatefulWidget {
  final int courseId;
  const ViewCourseDialog({Key? key, required this.courseId}) : super(key: key);

  @override
  _ViewCourseDialogState createState() => _ViewCourseDialogState();
}

class _ViewCourseDialogState extends State<ViewCourseDialog> {
  late Future<CourseDetail> _detailsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _detailsFuture = _apiService.fetchCourseDetails(widget.courseId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        width: 800, // Cân bằng với form sửa
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
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
                  const Text(
                    'THÔNG TIN HỌC PHẦN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            FutureBuilder<CourseDetail>(
              future: _detailsFuture,
              builder: (context, snapshot) {
                // Đang tải
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 400,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                // Lỗi
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                        child: Text(
                            'Lỗi tải chi tiết: ${snapshot.error}\n\nVui lòng kiểm tra API: GET /api/courses/${widget.courseId}')), // Thêm gợi ý kiểm tra API
                  );
                }
                // Thành công
                final course = snapshot.data!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Form 2x3 Cột
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildReadOnlyFormField('Mã học phần', course.code),
                                const SizedBox(height: 16),
                                _buildReadOnlyFormField('Số tín chỉ', course.credits.toString()),
                                const SizedBox(height: 16),
                                _buildReadOnlyFormField('Khoa phụ trách', course.departmentName),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildReadOnlyFormField('Tên học phần', course.name),
                                const SizedBox(height: 16),
                                _buildReadOnlyFormField('Loại học phần', course.subjectType),
                                // XÓA: Bỏ trường Bộ môn phụ trách và dùng placeholder
                                const SizedBox(height: 16), // Để cân bằng lưới 3x3
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Mô tả
                      _buildReadOnlyFormField('Mô tả', course.description, isMultiLine: true),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Footer
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tluBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                          ),
                          child: const Text('Quay lại',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // SỬA: Hàm build Read Only Field (giống form Add/Edit), có xử lý trường rỗng
  Widget _buildReadOnlyFormField(String label, String value, {bool isMultiLine = false}) {
    final displayValue = (value.isEmpty || value == 'N/A') ? 'Không có mô tả' : value;
    final isNoData = (value.isEmpty || value == 'N/A');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: isNoData ? '' : displayValue,
          readOnly: true,
          maxLines: isMultiLine ? 4 : 1,
          minLines: isMultiLine ? 3 : 1,
          style: TextStyle(color: isNoData ? Colors.grey.shade600 : Colors.black),
          decoration: InputDecoration(
            hintText: isNoData ? displayValue : null, // Hiển thị "Không có mô tả" dưới dạng hint
            hintStyle: TextStyle(color: Colors.grey.shade600),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: true,
            fillColor: Colors.grey[100], // Nền xám
            // SỬA LỖI: Thêm borderSide
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
      ],
    );
  }

  // THÊM: Helper mới để tạo một ô placeholder rỗng (dùng để cân bằng grid)
  Widget _buildEmptyPlaceholder({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '',
          readOnly: true,
          maxLines: 1,
          minLines: 1,
          style: TextStyle(color: Colors.grey.shade600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            filled: true,
            fillColor: Colors.grey[100],
            // SỬA LỖI: Thêm borderSide
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
      ],
    );
  }
}

// ==========================================================
// 2. POPUP THÊM / SỬA HỌC PHẦN (ĐÃ XÓA TRƯỜNG BỘ MÔN)
// ==========================================================
class AddEditCourseDialog extends StatefulWidget {
  final int? courseId; // Nếu null là Thêm, nếu có là Sửa
  // THÊM: Callback để gọi refresh từ HocPhanScreen
  final Future<void> Function() onRefresh;

  // SỬA: Thêm required this.onRefresh
  const AddEditCourseDialog({Key? key, this.courseId, required this.onRefresh}) : super(key: key);

  @override
  _AddEditCourseDialogState createState() => _AddEditCourseDialogState();
}

class _AddEditCourseDialogState extends State<AddEditCourseDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State cho Dropdown
  late Future<Map<String, dynamic>> _loadingFuture;
  final List<String> _courseTypes = ['Bắt buộc', 'Tùy chọn'];

  // State
  int? _selectedDepartmentId;
  String? _selectedType;

  // Biến để lưu lỗi trả về từ API (ví dụ: lỗi trùng mã)
  String? _codeApiError;

  // Trạng thái
  bool get _isEditMode => widget.courseId != null;
  bool _isSaving = false; // Trạng thái đang lưu

  @override
  void initState() {
    super.initState();
    // GỌI HÀM TẢI GỘP TẤT CẢ DỮ LIỆU BAN ĐẦU
    _loadingFuture = _loadInitialData();
  }

  // THÊM: Hàm tải gộp tất cả dữ liệu cần thiết
  Future<Map<String, dynamic>> _loadInitialData() async {
    // Luôn tải danh sách Khoa
    final departmentsFuture = _apiService.fetchDepartments().catchError((e) {
      // Xử lý lỗi tải khoa, trả về rỗng để form vẫn hiển thị nhưng không chọn được
      print('Lỗi tải Departments: $e');
      return <Department>[];
    });

    final results = <String, dynamic>{};

    // Tải danh sách Khoa
    results['departments'] = await departmentsFuture;

    // Nếu là Sửa, tải chi tiết khóa học
    if (_isEditMode) {
      try {
        final course = await _apiService.fetchCourseDetails(widget.courseId!);
        results['course'] = course;

        // Cập nhật giá trị ban đầu cho controllers và state
        if (mounted) {
          _codeController.text = course.code;
          _nameController.text = course.name;
          _creditsController.text = course.credits.toString();
          _descriptionController.text = course.description;
          // Set state để Dropdown hiển thị giá trị ban đầu sau khi FutureBuilder hoàn tất
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if(mounted) {
              setState(() {
                _selectedDepartmentId = course.departmentId;
                _selectedType = course.subjectType;
              });
            }
          });
        }
      } catch (e) {
        // Lỗi tải chi tiết khóa học
        // Ném lỗi để FutureBuilder chuyển sang trạng thái snapshot.hasError
        throw Exception('Không thể tải chi tiết học phần: $e');
      }
    }

    return results;
  }


  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Hàm xử lý khi nhấn Lưu/Xác nhận
  Future<void> _submitForm() async {
    // 1. Kiểm tra lỗi Frontend (Flutter validation)
    if (_formKey.currentState!.validate()) {
      // BẮT ĐẦU: Hiển thị trạng thái đang lưu
      setState(() {
        _isSaving = true;
        _codeApiError = null; // Xóa lỗi API cũ
      });

      // Tạo map dữ liệu (Đã xóa division_id)
      final data = {
        'code': _codeController.text,
        'name': _nameController.text,
        'credits': int.tryParse(_creditsController.text) ?? 0,
        // Đảm bảo không gửi null nếu chưa chọn (Backend nên xử lý)
        'department_id': _selectedDepartmentId,
        'subject_type': _selectedType,
        'description': _descriptionController.text,
      };

      try {
        if (_isEditMode) {
          await _apiService.updateCourse(widget.courseId!, data);
        } else {
          await _apiService.createCourse(data);
        }

        // --- THAO TÁC QUAN TRỌNG ĐÃ SỬA ---
        // 1. CHỜ: Chờ việc tải lại dữ liệu hoàn tất
        await widget.onRefresh();

        // 2. THÀNH CÔNG: Đóng dialog và trả về 'true'
        if (mounted) Navigator.of(context).pop(true);
        // ------------------------------------

      } catch (e) {
        // THẤT BẠI: Dừng trạng thái đang lưu
        setState(() => _isSaving = false);

        // 2. Bắt lỗi trùng mã (API 422 Unprocessable Entity)
        if (e.toString().contains('code') && e.toString().contains('422')) {
          setState(() {
            _codeApiError = 'Mã học phần này đã tồn tại. Vui lòng nhập mã khác.';
          });
        } else if (mounted) {
          // Lỗi khác (500, mạng,...)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Container(
        width: 800, // Form rộng hơn
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20.0),
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
                    _isEditMode
                        ? 'CHỈNH SỬA THÔNG TIN HỌC PHẦN'
                        : 'THÊM HỌC PHẦN MỚI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body: Sử dụng FutureBuilder để kiểm soát Loading toàn màn hình
            FutureBuilder<Map<String, dynamic>>(
              future: _loadingFuture,
              builder: (context, snapshot) {
                // 1. LOADING STATE: Hiển thị indicator toàn màn hình
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 500, // Chiều cao cố định cho màn hình tải
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // 2. ERROR STATE: Nếu có lỗi nghiêm trọng (ví dụ: lỗi tải chi tiết khi Sửa)
                if (snapshot.hasError) {
                  // Đóng dialog và hiển thị SnackBar lỗi
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  });
                  // Trả về widget rỗng tạm thời
                  return const SizedBox(height: 1);
                }

                // Lấy danh sách Khoa từ snapshot
                final departments = snapshot.data!['departments'] as List<Department>;

                // 3. SUCCESS STATE: Hiển thị Form sau khi tải xong
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
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
                                  _buildTextFormField(
                                    controller: _codeController,
                                    label: 'Mã học phần',
                                    hint: 'Nhập mã học phần',
                                    errorText: _codeApiError,
                                    readOnly: _isEditMode,
                                    validator: (value) =>
                                    (value?.isEmpty ?? true)
                                        ? 'Không được để trống'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextFormField(
                                    controller: _creditsController,
                                    label: 'Số tín chỉ',
                                    hint: 'Nhập số tín chỉ',
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true)
                                        return 'Không được để trống';
                                      if (int.tryParse(value!) == null)
                                        return 'Phải là số';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Trường Dropdown Khoa (CHỈ CẦN TRUYỀN DỮ LIỆU ĐÃ TẢI)
                                  _buildDropdownKhoa(departments),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Cột phải
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTextFormField(
                                    controller: _nameController,
                                    label: 'Tên học phần',
                                    hint: 'Nhập tên học phần',
                                    validator: (value) =>
                                    (value?.isEmpty ?? true)
                                        ? 'Không được để trống'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  // Trường Dropdown Loại học phần
                                  _buildDropdownLoai(),
                                  const SizedBox(height: 16),
                                  // Thêm khoảng trắng tương đương 1 trường
                                  const SizedBox(height: 56 + 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Mô tả (dài hết)
                        _buildTextFormField(
                          controller: _descriptionController,
                          label: 'Mô tả',
                          hint: 'Nhập mô tả',
                          maxLines: 3,
                          minLines: 3,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Footer (Buttons)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Nút Hủy (Nền trắng, viền đỏ, to và rộng hơn)
                            SizedBox(
                              height: 50, // Chiều cao cố định cho nút
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : () => Navigator.of(context).pop(), // Vô hiệu hóa khi đang lưu
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24), // Giảm vertical padding
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0)),
                                  side: const BorderSide(color: Colors.red, width: 1.5),
                                  backgroundColor: Colors.white, // Nền trắng
                                  foregroundColor: Colors.red,
                                ),
                                child:
                                const Text('Hủy bỏ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Nút Xác nhận (Nền xanh lá, to và rộng hơn)
                            SizedBox(
                              height: 50, // Chiều cao cố định cho nút
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _submitForm, // Vô hiệu hóa khi đang lưu
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50), // Màu xanh lá
                                  padding: const EdgeInsets.symmetric(horizontal: 24), // Giảm vertical padding
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0)),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                                    : Text(
                                    _isEditMode
                                        ? 'Lưu thay đổi'
                                        : 'Xác nhận',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // == Helper build Dropdowns (Đã bỏ FutureBuilder) ==

  // SỬA: Hàm này nhận departments đã được tải từ FutureBuilder bên ngoài
  Widget _buildDropdownKhoa(List<Department> departments) {

    // 1. Trường hợp Lỗi hoặc rỗng
    if (departments.isEmpty) {
      String hintText = 'Không có dữ liệu khoa';

      return _buildTextFormField(
        label: 'Khoa phụ trách',
        hint: hintText,
        readOnly: true,
        validator: (value) => null,
      );
    }

    // 2. Trường hợp Thành công (Hiển thị Dropdown)
    return _buildDropdownField<int>(
      label: 'Khoa phụ trách',
      hint: '--Chọn khoa phụ trách--',
      // SỬA: Giá trị được giữ bởi _selectedDepartmentId (được set trong initState)
      value: _selectedDepartmentId,
      items: departments.map((dept) {
        return DropdownMenuItem<int>(
          value: dept.id,
          child: Text(dept.name),
        );
      }).toList(),
      onChanged: (int? value) {
        setState(() {
          _selectedDepartmentId = value;
        });
      },
      validator: (value) => value == null ? 'Không được để trống' : null,
    );
  }

  Widget _buildDropdownLoai() {
    // Thêm chỉ định kiểu <String> cho _buildDropdownField
    return _buildDropdownField<String>(
      label: 'Loại học phần',
      hint: '--Chọn loại học phần--',
      value: _selectedType,
      items: _courseTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      // Chỉ định kiểu rõ ràng cho onChanged
      onChanged: (String? value) {
        setState(() => _selectedType = value);
      },
      validator: (value) => value == null ? 'Không được để trống' : null,
    );
  }

  // == Helper build Text & Dropdown (Giống nhau cho các form) ==

  Widget _buildTextFormField({
    TextEditingController? controller, // <--- Đã sửa lỗi missing argument
    required String label,
    required String hint,
    String? errorText, // THÊM: Tham số để hiển thị lỗi API
    bool readOnly = false,
    int maxLines = 1,
    int minLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${validator != null ? '*' : ''}',

            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText, // HIỂN THỊ LỖI API
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.white,
            // SỬA LỖI: Thêm borderSide
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: tluBlue)),
          ),
          validator: (value) {
            // Nếu có lỗi API, bỏ qua validator thường quy
            if (_codeApiError != null && label.contains('Mã học phần')) return null;
            return validator?.call(value);
          },
          // SỬA: Thêm onChanged để reset lỗi API khi người dùng gõ lại
          onChanged: (value) {
            if (_codeApiError != null && label.contains('Mã học phần')) {
              setState(() {
                _codeApiError = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${validator != null ? '*' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: onChanged == null ? Colors.grey[100] : Colors.white, // Màu xám nếu bị vô hiệu hóa
            // SỬA LỖI: Thêm borderSide
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: tluBlue)),
          ),
          isExpanded: true,
        ),
      ],
    );
  }
} // === KẾT THÚC CLASS _AddEditCourseDialogState ===

// ==========================================================
// 3. DIALOG XÁC NHẬN XÓA (Hàm dùng chung - ĐÃ CĂN CHỈNH NÚT)
// ==========================================================
// THÊM: Tham số onConfirmDelete
Future<dynamic> showDeleteConfirmationDialog(
    BuildContext context, {
      required String title,
      required String content,
      required Future<void> Function() onConfirmDelete, // <--- THÊM
    }) {
  return showDialog<dynamic>( // SỬA: Trả về dynamic để có thể là bool hoặc Exception
    context: context,
    builder: (BuildContext context) {
      bool _isDeleting = false;
      return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              // SỬA GIAO DIỆN DIALOG XÓA
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: const Center(
                child: Text(
                  'Thông báo!', // SỬA: Luôn dùng 'Thông báo!'
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              content: Text(
                content, // Nội dung động
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Điều chỉnh padding
              actions: <Widget>[
                // Nút Hủy (Nền trắng, viền đỏ, to và rộng hơn)
                Expanded(
                  child: SizedBox(
                    height: 50, // Chiều cao cố định
                    child: OutlinedButton(
                      onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false), // Vô hiệu hóa khi đang xóa
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24), // Giảm vertical padding
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                      child:
                      const Text('Hủy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Nút Xác nhận (Nền xanh lá, to và rộng hơn)
                Expanded(
                  child: SizedBox(
                    height: 50, // Chiều cao cố định
                    child: ElevatedButton(
                      onPressed: _isDeleting ? null : () async { // THÊM 'async'
                        setDialogState(() { _isDeleting = true; }); // Bắt đầu loading

                        try {
                          // CHỜ cho việc gọi API xóa và refresh data hoàn tất
                          await onConfirmDelete();
                          // Nếu thành công, đóng dialog và trả về true
                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          // Nếu thất bại, đóng dialog và trả về lỗi
                          if (context.mounted) Navigator.of(context).pop(e as Exception);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Màu xanh lá
                        padding: const EdgeInsets.symmetric(horizontal: 24), // Giảm vertical padding
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      // HIỂN THỊ LOADING XOAY TRÒN
                      child: _isDeleting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                          : const Text('Xác nhận',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            );
          }
      );
    },
  );
}