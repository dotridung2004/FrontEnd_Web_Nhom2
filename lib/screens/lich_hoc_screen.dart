import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for DateFormat
import '../api_service.dart'; // Import ApiService
import '../models/schedule.dart'; // Import model Schedule (*** PHẢI CẬP NHẬT ***)

// Enum để quản lý trạng thái của dialog
enum DialogMode { add, edit, view }

class LichHocScreen extends StatefulWidget {
  const LichHocScreen({Key? key}) : super(key: key);

  @override
  _LichHocScreenState createState() => _LichHocScreenState();
}

// Lớp _LichHocScreenState (Giữ nguyên phần lớn, chỉ sửa hàm gọi _loadSchedules)
class _LichHocScreenState extends State<LichHocScreen> {
  // Màu sắc
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;

  // Trạng thái API
  final ApiService _apiService = ApiService(); // Khởi tạo ApiService
  bool _isLoading = true;
  String? _error;

  // Danh sách dữ liệu
  List<Schedule> _allSchedules = []; // Danh sách đầy đủ từ API
  List<Schedule> _filteredSchedules = []; // Danh sách sau khi tìm kiếm
  List<Schedule> _displayedSchedules = []; // Danh sách hiển thị trên trang hiện tại

  // Trạng thái tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  // Trạng thái phân trang
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10; // 10 người mỗi trang

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSchedules(resetPage: true); // <-- THAY ĐỔI: Thêm resetPage: true
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// (CẬP NHẬT) Hàm để tải hoặc tải lại dữ liệu từ API
  Future<void> _loadSchedules({bool resetPage = false}) async { // <-- THAY ĐỔI: Thêm tham số
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    // (MỚI) Reset trang về 1 nếu được yêu cầu (khi Thêm/Sửa/Xóa)
    if (resetPage && mounted) {
      setState(() {
        _currentPage = 1;
      });
    }

    try {
      final schedules = await _apiService.fetchSchedules();
      if (mounted) {
        setState(() {
          _allSchedules = schedules;
          _isLoading = false;
          _updateLists(); // Cập nhật danh sách hiển thị
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Được gọi khi nội dung ô tìm kiếm thay đổi
  void _onSearchChanged() {
    setState(() {
      _currentPage = 1; // Quay về trang 1 khi tìm kiếm
      _updateLists();
    });
  }

  /// Hàm chính để lọc và phân trang
  void _updateLists() {
    final query = _searchController.text.toLowerCase();

    // 1. Lọc (Filter)
    if (query.isEmpty) {
      _filteredSchedules = List.from(_allSchedules);
    } else {
      _filteredSchedules = _allSchedules.where((schedule) {
        // Tìm kiếm trên nhiều trường
        return schedule.teacherName.toLowerCase().contains(query) ||
            schedule.classCode.toLowerCase().contains(query) ||
            schedule.courseName.toLowerCase().contains(query) ||
            schedule.semester.toLowerCase().contains(query) ||
            schedule.roomName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Phân trang (Paginate)
    _totalPages = (_filteredSchedules.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1; // Đảm bảo luôn có ít nhất 1 trang

    // Đảm bảo trang hiện tại hợp lệ
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;

    if (endIndex > _filteredSchedules.length) {
      endIndex = _filteredSchedules.length;
    }

    _displayedSchedules = _filteredSchedules.sublist(startIndex, endIndex);
  }

  // Hàm build UI chính
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    return _buildContent(context, _displayedSchedules);
  }

  /// Widget chứa nội dung (Tiêu đề, Nút, Bảng)
  Widget _buildContent(BuildContext context, List<Schedule> schedules) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Phần Header: Tiêu đề, nút Thêm, Tìm kiếm - Giữ nguyên)
          Wrap(
            spacing: 24.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Lịch học",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút Thêm
                  ElevatedButton.icon(
                    onPressed: () {
                      _showScheduleDialog(context, mode: DialogMode.add);
                    },
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Thêm", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tluBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Thanh Tìm kiếm
                  Container(
                    width: 300,
                    child: TextField(
                      controller: _searchController, // Gắn controller
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm...",
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
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // ... (Bảng DataTable - Giữ nguyên)
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
                    columns: const [
                      DataColumn(label: Text('STT')),
                      DataColumn(label: Text('Tên giảng viên')),
                      DataColumn(label: Text('Lớp học phần')),
                      DataColumn(label: Text('Học phần')),
                      DataColumn(label: Text('Học kỳ')),
                      DataColumn(label: Text('Phòng')),
                      DataColumn(label: Text('Thao tác')),
                    ],
                    rows: List.generate(
                      schedules.length, // Dùng danh sách đã phân trang
                          (index) {
                        // Tính STT dựa trên trang hiện tại
                        int stt = (_currentPage - 1) * _itemsPerPage + index + 1;
                        return _buildDataRow(stt, schedules[index], context);
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // ... (Phân trang - Giữ nguyên)
          _buildPaginationControls(),
        ],
      ),
    );
  }

  /// Widget cho các nút phân trang
  Widget _buildPaginationControls() {
    String startItem = _filteredSchedules.isEmpty ? '0' : ((_currentPage - 1) * _itemsPerPage + 1).toString();
    String endItem = (_currentPage * _itemsPerPage > _filteredSchedules.length)
        ? _filteredSchedules.length.toString()
        : (_currentPage * _itemsPerPage).toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_filteredSchedules.isNotEmpty)
          Text(
            "Hiển thị $startItem - $endItem / ${_filteredSchedules.length} kết quả",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        if (_filteredSchedules.isEmpty)
          Text(
            "Không tìm thấy kết quả",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: _currentPage == 1 ? null : () {
            setState(() { _currentPage--; _updateLists(); });
          },
        ),
        Text(
          "Trang $_currentPage / $_totalPages",
          style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _currentPage == _totalPages ? null : () {
            setState(() { _currentPage++; _updateLists(); });
          },
        ),
      ],
    );
  }


  /// Helper để tạo một hàng dữ liệu (DataRow)
  DataRow _buildDataRow(int stt, Schedule schedule, BuildContext context) {
    // *** QUAN TRỌNG: schedule.teacherName,... phải được định nghĩa trong Model Schedule.dart ***
    // và được map từ API (trong ScheduleController::index)
    return DataRow(
      cells: [
        DataCell(Text(stt.toString())),
        DataCell(Text(schedule.teacherName)),
        DataCell(Text(schedule.classCode)),
        DataCell(Text(schedule.courseName)),
        DataCell(Text(schedule.semester)),
        DataCell(Text(schedule.roomName)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.info_outline, color: iconView),
                onPressed: () { _showScheduleDialog(context, mode: DialogMode.view, schedule: schedule); },
                tooltip: "Xem",
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: iconEdit),
                onPressed: () { _showScheduleDialog(context, mode: DialogMode.edit, schedule: schedule); },
                tooltip: "Sửa",
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconDelete),
                onPressed: () { _showDeleteConfirmDialog(context, schedule); },
                tooltip: "Xóa",
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// (CẬP NHẬT) Hiển thị dialog Thêm/Sửa/Xem
  void _showScheduleDialog(BuildContext context, {required DialogMode mode, Schedule? schedule}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ScheduleDialog(
          mode: mode,
          schedule: schedule, // Truyền schedule chứa ID vào dialog
          apiService: _apiService,
          onSave: () {
            Navigator.of(dialogContext).pop(); // Đóng dialog
            _loadSchedules(resetPage: true); // <-- THAY ĐỔI: Thêm resetPage: true
          },
        );
      },
    );
  }

  /// (CẬP NHẬT) Hiển thị dialog Xác nhận Xóa
  void _showDeleteConfirmDialog(BuildContext context, Schedule schedule) async {
    // ... (Giữ nguyên logic)
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          title: Text("Thông báo!"),
          content: Text("Bạn chắc chắn muốn xóa lịch học này?"),
          actionsPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text("Hủy"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                backgroundColor: Colors.grey[200],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text("Xác nhận"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green, // Màu xanh lá cho xác nhận
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteSchedule(schedule.id); // Giả sử schedule có 'id'
        _loadSchedules(resetPage: true); // <-- THAY ĐỔI: Thêm resetPage: true

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xóa lịch học thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi xóa: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// -------------------------------------------------------------
// --- Widget Dialog cho Thêm/Sửa/Xem (_ScheduleDialog) - VIẾT LẠI ---
// -------------------------------------------------------------
class _ScheduleDialog extends StatefulWidget {
  final DialogMode mode;
  final Schedule? schedule; // Bây giờ chứa ID
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

  // --- State Mới ---
  int? _selectedAssignmentId;
  int? _selectedRoomId;
  late TextEditingController _sessionController;
  DateTime? _selectedDate;

  bool _isReadOnly = false;
  bool _isLoading = false;

  // --- Future cho Dropdowns ---
  late Future<List<ClassCourseAssignment>> _assignmentsFuture;
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();

    // Tải dữ liệu cho dropdowns
    _assignmentsFuture = widget.apiService.fetchClassCourseAssignments();
    _roomsFuture = widget.apiService.fetchRooms();

    // Khởi tạo giá trị cho form Sửa/Xem (Edit/View)
    if (widget.mode == DialogMode.edit || widget.mode == DialogMode.view) {
      // *** QUAN TRỌNG: Model Schedule.dart PHẢI có các trường này ***
      _selectedAssignmentId = widget.schedule?.classCourseAssignmentId;
      _selectedRoomId = widget.schedule?.roomId;
      _sessionController = TextEditingController(text: widget.schedule?.session ?? '');
      _selectedDate = widget.schedule?.date; // Giả sử model Schedule.dart có trường date là DateTime
    } else {
      // Form Thêm (Add) - giá trị mặc định
      _sessionController = TextEditingController();
      _selectedDate = DateTime.now(); // Mặc định là ngày hiện tại
    }

    _isReadOnly = widget.mode == DialogMode.view;
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  /// Xử lý khi nhấn nút Lưu (Thêm/Sửa) - VIẾT LẠI HOÀN TOÀN
  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      // Kiểm tra các giá trị đã được chọn
      if (_selectedAssignmentId == null || _selectedRoomId == null || _selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vui lòng chọn đầy đủ thông tin"), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      // 1. Định dạng ngày sang 'yyyy-MM-dd'
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      // 2. TẠO MAP DỮ LIỆU MỚI (chứa ID)
      final data = {
        'class_course_assignment_id': _selectedAssignmentId,
        'room_id': _selectedRoomId,
        'date': formattedDate,
        'session': _sessionController.text,
        // 'status': 'scheduled', // Backend sẽ tự gán nếu không gửi
      };

      try {
        if (widget.mode == DialogMode.add) {
          await widget.apiService.createSchedule(data);
        } else if (widget.mode == DialogMode.edit) {
          await widget.apiService.updateSchedule(widget.schedule!.id, data);
        }
        widget.onSave(); // Gọi callback để tải lại danh sách và đóng dialog
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi lưu: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // --- Các hàm lấy tiêu đề và nút actions (Giữ nguyên) ---
  String _getTitle() {
    switch (widget.mode) {
      case DialogMode.add: return "Thêm lịch học";
      case DialogMode.edit: return "Sửa thông tin lịch học";
      case DialogMode.view: return "Xem thông tin lịch học";
    }
  }

  List<Widget> _getActions() {
    if (_isLoading) {
      return [CircularProgressIndicator()];
    }
    if (widget.mode == DialogMode.view) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Xác nhận"),
          style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text("Hủy"),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[700], backgroundColor: Colors.grey[200]),
      ),
      TextButton(
        onPressed: _handleSave,
        child: Text("Lưu"),
        style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Color headerColor = const Color(0xFF4FA8E1); // Màu xanh dương nhạt

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      titlePadding: EdgeInsets.zero,
      title: Container( /* ... (Giữ nguyên phần Header của Dialog) ... */
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        decoration: BoxDecoration(
            color: headerColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            )
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getTitle(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      content: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: BoxConstraints(maxWidth: 800),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
            // --- BỐ CỤC FORM MỚI ---
            child: Column( // Dùng Column thay vì Wrap để dễ kiểm soát hơn
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAssignmentDropdown(), // Dropdown Phân công (GV-Môn-Lớp)
                SizedBox(height: 16),
                _buildRoomDropdown(),       // Dropdown Phòng
                SizedBox(height: 16),
                _buildDatePicker(context),   // Nút chọn Ngày
                SizedBox(height: 16),
                _buildTextField("Ca học (ví dụ: 1-3)", _sessionController), // TextField Ca học
              ],
            ),
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      actionsAlignment: MainAxisAlignment.end,
      actions: _getActions(),
    );
  }

  // --- CÁC HÀM HELPER MỚI CHO FORM ---

  /// Helper build Dropdown Phân công
  Widget _buildAssignmentDropdown() {
    return FutureBuilder<List<ClassCourseAssignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          content = Text("Lỗi tải DS phân công", style: TextStyle(color: Colors.red));
        } else {
          content = DropdownButtonFormField<int>(
            value: _selectedAssignmentId,
            hint: Text("Chọn GV - Môn - Lớp *"),
            isExpanded: true, // Cho phép text dài hiển thị
            decoration: _inputDecoration(""), // Bỏ label trùng lặp
            items: snapshot.data!.map((assignment) {
              return DropdownMenuItem<int>(
                value: assignment.id,
                child: Text(assignment.displayName, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: _isReadOnly ? null : (value) {
              setState(() => _selectedAssignmentId = value);
            },
            validator: (value) => value == null ? 'Vui lòng chọn' : null,
          );
        }
        // Thêm label bên ngoài Dropdown
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phân công (GV - Môn - Lớp) *", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            SizedBox(height: 4),
            content,
          ],
        );
      },
    );
  }

  /// Helper build Dropdown Phòng
  Widget _buildRoomDropdown() {
    return FutureBuilder<List<Room>>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = Center(child: CircularProgressIndicator(strokeWidth: 2));
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          content = Text("Lỗi tải DS phòng", style: TextStyle(color: Colors.red));
        } else {
          content = DropdownButtonFormField<int>(
            value: _selectedRoomId,
            hint: Text("Chọn phòng học *"),
            decoration: _inputDecoration(""), // Bỏ label trùng lặp
            items: snapshot.data!.map((room) {
              return DropdownMenuItem<int>(
                value: room.id,
                child: Text(room.name),
              );
            }).toList(),
            onChanged: _isReadOnly ? null : (value) {
              setState(() => _selectedRoomId = value);
            },
            validator: (value) => value == null ? 'Vui lòng chọn' : null,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phòng học *", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            SizedBox(height: 4),
            content,
          ],
        );
      },
    );
  }

  /// Helper build Nút chọn Ngày
  Widget _buildDatePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Ngày học *", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        SizedBox(height: 4),
        TextFormField(
          // Dùng TextFormField để có viền và validator
          readOnly: true, // Không cho nhập trực tiếp
          controller: TextEditingController( // Hiển thị ngày đã chọn
              text: _selectedDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDate!)
          ),
          decoration: _inputDecoration("").copyWith( // Thêm icon lịch
              suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              hintText: "Chọn ngày học *"
          ),
          onTap: _isReadOnly ? null : () async { // Mở DatePicker khi nhấn vào
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null && picked != _selectedDate) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          validator: (value) => _selectedDate == null ? 'Vui lòng chọn ngày' : null,
        ),
      ],
    );
  }


  /// Helper build Text Field (cho Ca học)
  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: _isReadOnly,
      decoration: _inputDecoration(label), // Sử dụng hàm trang trí chung
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        return null;
      },
    );
  }

  // (MỚI) Hàm helper để tạo InputDecoration chung
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label.isNotEmpty ? "$label *" : null, // Chỉ hiện label nếu có
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)),
        filled: _isReadOnly,
        fillColor: _isReadOnly ? Colors.grey[100] : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0)
    );
  }

}