import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for DateFormat
import '../api_service.dart'; // Import ApiService
import '../models/schedule.dart'; // Import model Schedule
import '../models/room.dart'; // <-- BỔ SUNG IMPORT
import '../models/class_course_assignment.dart'; // <-- BỔ SUNG IMPORT

// Enum (Keep as is)
enum DialogMode { add, edit, view }

// --- 1. Màn hình chính (Đã refactor theo chuẩn GiangVienScreen) ---
class LichHocScreen extends StatefulWidget {
  const LichHocScreen({Key? key}) : super(key: key);

  @override
  _LichHocScreenState createState() => _LichHocScreenState();
}

class _LichHocScreenState extends State<LichHocScreen> {
  // --- State and Colors (Chuẩn hóa) ---
  static const Color tluBlue = Color(0xFF005A9C);
  static const Color iconView = Colors.blue;
  static const Color iconEdit = Colors.green;
  static const Color iconDelete = Colors.red;
  static const Color screenBg = Color(0xFFF0F4F8); // Thêm màu nền

  final ApiService _apiService = ApiService();

  // Future cho FutureBuilder
  late Future<List<Schedule>> _schedulesFuture;

  // Danh sách để lọc và phân trang
  List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];
  List<Schedule> _displayedSchedules = []; // Danh sách đã phân trang

  final TextEditingController _searchController = TextEditingController();

  // State phân trang
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterData);
    _loadSchedules(); // Tải dữ liệu lần đầu
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  /// Tải (hoặc tải lại) toàn bộ dữ liệu từ API
  void _loadSchedules() {
    setState(() {
      // Gán future mới để FutureBuilder rebuild
      _schedulesFuture = _apiService.fetchSchedules();
    });

    _schedulesFuture.then((schedules) {
      if (mounted) {
        setState(() {
          _allSchedules = schedules;
          _filterData(); // Lọc và cập nhật UI sau khi có dữ liệu
        });
      }
    }).catchError((e) {
      // FutureBuilder sẽ tự hiển thị lỗi
      if (mounted) {
        debugPrint('Lỗi khi tải lịch học: $e');
      }
    });
  }

  /// Lọc dữ liệu từ _allSchedules dựa trên thanh tìm kiếm
  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSchedules = List.from(_allSchedules);
      } else {
        _filteredSchedules = _allSchedules.where((schedule) {
          return schedule.teacherName.toLowerCase().contains(query) ||
              schedule.classCode.toLowerCase().contains(query) ||
              schedule.courseName.toLowerCase().contains(query) ||
              schedule.semester.toLowerCase().contains(query) ||
              schedule.roomName.toLowerCase().contains(query);
        }).toList();
      }
      _currentPage = 1; // Reset về trang 1
      _updatePaginatedList(); // Cập nhật danh sách hiển thị
    });
  }

  /// Cập nhật danh sách _displayedSchedules dựa trên trang hiện tại
  void _updatePaginatedList() {
    // <<< SỬA 5: Sửa lỗi logic tính _totalPages (giống GiangVienScreen)
    final int totalItems = _filteredSchedules.length;
    _totalPages = _itemsPerPage > 0 ? (totalItems / _itemsPerPage).ceil() : 0;

    if (_totalPages == 0) _totalPages = 1;
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredSchedules.length) {
      endIndex = _filteredSchedules.length;
    }

    _displayedSchedules = _filteredSchedules.sublist(startIndex, endIndex);
  }

  /// Helper để chuyển trang
  void _goToPage(int page) {
    if (page < 1) page = 1;
    if (page > _totalPages) page = _totalPages;

    setState(() {
      _currentPage = page;
      _updatePaginatedList(); // Cập nhật lại _displayedSchedules
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg, // Áp dụng màu nền
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildControls(),
          const SizedBox(height: 16),
          FutureBuilder<List<Schedule>>(
            future: _schedulesFuture,
            builder: (context, snapshot) {
              // 1. Trạng thái Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Trạng thái Lỗi
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              // 3. Trạng thái Không có dữ liệu (từ bộ lọc)
              if (_filteredSchedules.isEmpty) {
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
                        'Không tìm thấy lịch học nào.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      )
                  ),
                );
              }

              // 4. Trạng thái Thành công: Hiển thị DataTable và Phân trang
              return Column(
                children: [
                  _buildDataTable(_displayedSchedules), // Chỉ hiển thị danh sách đã phân trang
                  const SizedBox(height: 16),
                  if (_totalPages > 1) _buildPaginationControls(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Xây dựng thanh điều khiển (Thêm, Tìm kiếm)
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // <<< SỬA 1: Bỏ icon, đồng bộ style nút "Thêm"
        ElevatedButton(
          onPressed: () => _showScheduleDialog(context, mode: DialogMode.add),
          style: ElevatedButton.styleFrom(
            backgroundColor: tluBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            minimumSize: const Size(0, 50),
          ),
          child: const Text("Thêm", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Tìm kiếm...",
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
    );
  }

  /// Xây dựng Bảng dữ liệu
  Widget _buildDataTable(List<Schedule> schedules) {
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
                    DataColumn(label: Text('Tên giảng viên')),
                    DataColumn(label: Text('Lớp học phần')),
                    DataColumn(label: Text('Học phần')),
                    DataColumn(label: Text('Học kỳ')),
                    DataColumn(label: Text('Phòng')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: List.generate(schedules.length, (index) {
                    int stt = (_currentPage - 1) * _itemsPerPage + index + 1;
                    return _buildDataRow(stt, schedules[index], context);
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Xây dựng một hàng trong Bảng (Giữ nguyên - đã đồng bộ)
  DataRow _buildDataRow(int stt, Schedule schedule, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(schedule.teacherName)),
        DataCell(Text(schedule.classCode)),
        DataCell(Text(schedule.courseName)),
        DataCell(Text(schedule.semester)),
        DataCell(Text(schedule.roomName)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.info_outline, color: iconView, size: 20), onPressed: () => _showScheduleDialog(context, mode: DialogMode.view, schedule: schedule), tooltip: "Xem", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.edit_outlined, color: iconEdit, size: 20), onPressed: () => _showScheduleDialog(context, mode: DialogMode.edit, schedule: schedule), tooltip: "Sửa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.delete_outline, color: iconDelete, size: 20), onPressed: () => _showDeleteConfirmDialog(context, schedule), tooltip: "Xóa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
          ],
        )),
      ],
    );
  }

  /// Xây dựng thanh điều khiển Phân trang (Chuẩn hóa)
  Widget _buildPaginationControls() {
    // <<< SỬA 2: Đồng bộ text phân trang (giống GiangVienScreen)
    final int totalItems = _filteredSchedules.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Trang $_currentPage / $_totalPages (Tổng: $totalItems)'),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
          tooltip: 'Trang đầu',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          tooltip: 'Trang trước',
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
          tooltip: 'Trang sau',
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: _currentPage < _totalPages ? () => _goToPage(_totalPages) : null,
          tooltip: 'Trang cuối',
        ),
      ],
    );
  }

  /// Hiển thị Dialog Thêm/Sửa/Xem
  void _showScheduleDialog(BuildContext context, {required DialogMode mode, Schedule? schedule}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không đóng khi nhấn bên ngoài
      builder: (BuildContext dialogContext) {
        return _ScheduleDialog(
          mode: mode,
          schedule: schedule,
          apiService: _apiService,
          onSave: () {
            Navigator.of(dialogContext).pop();
            _loadSchedules(); // Tải lại toàn bộ dữ liệu
          },
        );
      },
    );
  }

  /// Hiển thị dialog Xác nhận Xóa
  void _showDeleteConfirmDialog(BuildContext context, Schedule schedule) async {
    // <<< SỬA 3: Đồng bộ dialog XÁC NHẬN XÓA (giống GiangVienScreen)
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa lịch học của "${schedule.teacherName}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteSchedule(schedule.id);

        // Hiển thị SnackBar thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã xóa lịch học thành công!"),
            backgroundColor: Colors.green, // Dùng xanh lá cho thành công
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            duration: Duration(seconds: 2),
          ),
        );

        _loadSchedules(); // Tải lại SAU KHI xóa và hiển thị snackbar

      } catch (e) {
        // Hiển thị SnackBar lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi xóa: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }
}

// -------------------------------------------------------------
// --- 2. Dialog Thêm/Sửa/Xem (Đã refactor Form) ---
// -------------------------------------------------------------
class _ScheduleDialog extends StatefulWidget {
  final DialogMode mode;
  final Schedule? schedule;
  final ApiService apiService;
  final VoidCallback onSave;

  const _ScheduleDialog({
    Key? key,
    required this.mode,
    this.schedule,
    required this.apiService,
    required this.onSave,
  }) : super(key: key);

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAssignmentId;
  int? _selectedRoomId;
  late TextEditingController _sessionController;
  DateTime? _selectedDate;

  bool _isReadOnly = false;
  bool _isLoading = false;

  // Futures cho dropdowns
  late Future<List<ClassCourseAssignment>> _assignmentsFuture;
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu cho dropdowns
    _assignmentsFuture = widget.apiService.fetchClassCourseAssignments();
    _roomsFuture = widget.apiService.fetchRooms();

    // Điền dữ liệu cho mode Edit/View
    if (widget.mode == DialogMode.edit || widget.mode == DialogMode.view) {
      _selectedAssignmentId = widget.schedule?.classCourseAssignmentId;
      _selectedRoomId = widget.schedule?.roomId;
      _sessionController = TextEditingController(text: widget.schedule?.session ?? '');
      _selectedDate = widget.schedule?.date;
    } else {
      // Mode Add
      _sessionController = TextEditingController();
      _selectedDate = DateTime.now(); // Mặc định là hôm nay
    }

    _isReadOnly = widget.mode == DialogMode.view;
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  /// Xử lý khi nhấn nút Lưu
  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAssignmentId == null || _selectedRoomId == null || _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng chọn đầy đủ thông tin"), backgroundColor: Colors.red)
        );
        return;
      }

      setState(() => _isLoading = true);
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final data = {
        'class_course_assignment_id': _selectedAssignmentId,
        'room_id': _selectedRoomId,
        'date': formattedDate,
        'session': _sessionController.text,
      };

      try {
        String successMessage;
        if (widget.mode == DialogMode.add) {
          await widget.apiService.createSchedule(data);
          successMessage = "Thêm lịch học thành công!";
        } else { // Mode Edit
          await widget.apiService.updateSchedule(widget.schedule!.id, data);
          successMessage = "Cập nhật lịch học thành công!";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        widget.onSave(); // Gọi callback (đóng dialog, tải lại danh sách)

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Lỗi khi lưu: $e"),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(10)
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // --- Helpers cho Tiêu đề và Nút Bấm ---
  String _getTitle() {
    switch (widget.mode) {
      case DialogMode.add: return "Thêm lịch học";
      case DialogMode.edit: return "Sửa thông tin lịch học";
      case DialogMode.view: return "Xem thông tin lịch học";
    }
  }

  // <<< SỬA 4: Đồng bộ các nút Hủy/Lưu/Xác nhận trong dialog (style giống GiangVienScreen)
  List<Widget> _getActions() {
    if (_isLoading) {
      return [const Center(child: CircularProgressIndicator())];
    }

    // Nút cho chế độ XEM
    if (widget.mode == DialogMode.view) {
      return [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ];
    }

    // Nút cho chế độ THÊM / SỬA
    return [
      OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Hủy'),
      ),
      const SizedBox(width: 16),
      ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Lưu', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng màu tluBlue cho nhất quán
    const Color headerColor = Color(0xFF005A9C);
    // Màu nền content dialog cho đồng bộ
    const Color dialogContentBgColor = Color(0xFFF5F5F5);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero, // Tắt padding mặc định
      backgroundColor: dialogContentBgColor, // Đặt màu nền content
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: const BoxDecoration(
          color: headerColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(8.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getTitle(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(maxWidth: 800), // Giới hạn chiều rộng
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Thêm padding_all 24.0 cho đồng bộ
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAssignmentDropdown(),
                const SizedBox(height: 16),
                _buildRoomDropdown(),
                const SizedBox(height: 16),
                _buildDatePicker(context),
                const SizedBox(height: 16),
                _buildTextField("Ca học (ví dụ: 1-3)", _sessionController),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      actionsAlignment: MainAxisAlignment.end,
      actions: _getActions(),
    );
  }

  // --- Helpers xây dựng Form (Đã chuẩn hóa) ---

  /// Helper build Dropdown Phân công
  Widget _buildAssignmentDropdown() {
    return FutureBuilder<List<ClassCourseAssignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          content = const Text("Lỗi tải DS phân công", style: TextStyle(color: Colors.red));
        } else {
          final uniqueAssignments = <String, int>{}; // Map<DisplayName, ID>
          for (var assignment in snapshot.data!) {
            uniqueAssignments.putIfAbsent(assignment.displayName, () => assignment.id);
          }
          final dropdownItems = uniqueAssignments.entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.value,
              child: Text(entry.key, overflow: TextOverflow.ellipsis),
            );
          }).toList();

          content = DropdownButtonFormField<int>(
            value: uniqueAssignments.containsValue(_selectedAssignmentId) ? _selectedAssignmentId : null,
            hint: const Text("Chọn GV - Môn - Lớp"),
            isExpanded: true,
            decoration: _inputDecoration(),
            items: dropdownItems,
            onChanged: _isReadOnly ? null : (value) {
              setState(() => _selectedAssignmentId = value);
            },
            validator: (value) => value == null ? 'Vui lòng chọn' : null,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phân công (GV - Môn - Lớp) *", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            content,
          ],
        );
      },
    );
  }

  /// Helper build Dropdown Phòng học
  Widget _buildRoomDropdown() {
    return FutureBuilder<List<Room>>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          content = const Text("Lỗi tải DS phòng", style: TextStyle(color: Colors.red));
        } else {
          content = DropdownButtonFormField<int>(
            value: _selectedRoomId,
            hint: const Text("Chọn phòng học"),
            decoration: _inputDecoration(),
            items: snapshot.data!.map((room) => DropdownMenuItem<int>(
              value: room.id,
              child: Text(room.name),
            )).toList(),
            onChanged: _isReadOnly ? null : (value) => setState(() => _selectedRoomId = value),
            validator: (value) => value == null ? 'Vui lòng chọn' : null,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phòng học *", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            content,
          ],
        );
      },
    );
  }

  /// Helper build Chọn ngày
  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ngày học *", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
              text: _selectedDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDate!)
          ),
          decoration: _inputDecoration().copyWith(
              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              hintText: "Chọn ngày học"
          ),
          onTap: _isReadOnly ? null : () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() => _selectedDate = picked);
            }
          },
          validator: (value) => _selectedDate == null ? 'Vui lòng chọn ngày' : null,
        ),
      ],
    );
  }

  /// Helper build Trường văn bản (Ca học)
  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label *", style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: _isReadOnly,
          decoration: _inputDecoration().copyWith(
              hintText: "Nhập $label"
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Không được bỏ trống' : null,
        ),
      ],
    );
  }

  /// Helper build style cho Input (Đồng bộ style với GiangVienScreen)
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: _isReadOnly ? Colors.grey[200] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}