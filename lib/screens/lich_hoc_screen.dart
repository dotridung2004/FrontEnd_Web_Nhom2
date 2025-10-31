import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl for DateFormat
import '../api_service.dart'; // Import ApiService
import '../models/schedule.dart'; // Import model Schedule

// Enum (Keep as is)
enum DialogMode { add, edit, view }

// LichHocScreen StatefulWidget (Keep as is)
class LichHocScreen extends StatefulWidget {
  const LichHocScreen({Key? key}) : super(key: key);

  @override
  _LichHocScreenState createState() => _LichHocScreenState();
}

// _LichHocScreenState (Keep as is, except verify _showDeleteConfirmDialog)
class _LichHocScreenState extends State<LichHocScreen> {
  // ... (Keep colors, ApiService, lists, controllers, pagination state)
  final Color tluBlue = const Color(0xFF005A9C);
  final Color iconView = Colors.blue;
  final Color iconEdit = Colors.green;
  final Color iconDelete = Colors.red;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];
  List<Schedule> _displayedSchedules = [];
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSchedules(resetPage: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules({bool resetPage = false}) async {
    // ... (Keep logic)
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
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
          _updateLists();
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

  void _onSearchChanged() {
    // ... (Keep logic)
    setState(() {
      _currentPage = 1;
      _updateLists();
    });
  }

  void _updateLists() {
    // ... (Keep logic)
    final query = _searchController.text.toLowerCase();
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
    _totalPages = (_filteredSchedules.length / _itemsPerPage).ceil();
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

  @override
  Widget build(BuildContext context) {
    // ... (Keep logic)
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }
    return _buildContent(context, _displayedSchedules);
  }

  Widget _buildContent(BuildContext context, List<Schedule> schedules) {
    // ... (Keep logic for Header, DataTable, Pagination)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap( /* Header */
            spacing: 24.0, runSpacing: 16.0, alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [ /* Title, Add Button, Search Bar */
              Text("Lịch học", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                ElevatedButton.icon(
                  onPressed: () => _showScheduleDialog(context, mode: DialogMode.add),
                  icon: Icon(Icons.add, color: Colors.white), label: Text("Thêm", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: tluBlue, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))),
                ),
                SizedBox(width: 16),
                Container(width: 300, child: TextField(controller: _searchController, decoration: InputDecoration(hintText: "Tìm kiếm...", prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 12.0)))),
              ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container( /* DataTable */
            width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.grey.shade300)),
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(scrollDirection: Axis.horizontal, child: ConstrainedBox(constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(headingRowColor: MaterialStateProperty.all(tluBlue), headingTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  columns: const [ /* Columns */
                    DataColumn(label: Text('STT')), DataColumn(label: Text('Tên giảng viên')), DataColumn(label: Text('Lớp học phần')),
                    DataColumn(label: Text('Học phần')), DataColumn(label: Text('Học kỳ')), DataColumn(label: Text('Phòng')), DataColumn(label: Text('Thao tác')),
                  ],
                  rows: List.generate(schedules.length, (index) { /* Rows */
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
          _buildPaginationControls(), /* Pagination */
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    // ... (Keep logic)
    String startItem = _filteredSchedules.isEmpty ? '0' : ((_currentPage - 1) * _itemsPerPage + 1).toString();
    String endItem = (_currentPage * _itemsPerPage > _filteredSchedules.length) ? _filteredSchedules.length.toString() : (_currentPage * _itemsPerPage).toString();
    return Row( mainAxisAlignment: MainAxisAlignment.end, children: [
      if (_filteredSchedules.isNotEmpty) Text("Hiển thị $startItem - $endItem / ${_filteredSchedules.length} kết quả", style: TextStyle(fontSize: 16, color: Colors.black54)),
      if (_filteredSchedules.isEmpty) Text("Không tìm thấy kết quả", style: TextStyle(fontSize: 16, color: Colors.black54)),
      SizedBox(width: 16),
      IconButton(icon: Icon(Icons.chevron_left), onPressed: _currentPage == 1 ? null : () => setState(() { _currentPage--; _updateLists(); })),
      Text("Trang $_currentPage / $_totalPages", style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
      IconButton(icon: Icon(Icons.chevron_right), onPressed: _currentPage == _totalPages ? null : () => setState(() { _currentPage++; _updateLists(); })),
    ],
    );
  }

  DataRow _buildDataRow(int stt, Schedule schedule, BuildContext context) {
    // ... (Keep logic)
    return DataRow(cells: [
      DataCell(Text(stt.toString())), DataCell(Text(schedule.teacherName)), DataCell(Text(schedule.classCode)),
      DataCell(Text(schedule.courseName)), DataCell(Text(schedule.semester)), DataCell(Text(schedule.roomName)),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: Icon(Icons.info_outline, color: iconView), onPressed: () => _showScheduleDialog(context, mode: DialogMode.view, schedule: schedule), tooltip: "Xem"),
        IconButton(icon: Icon(Icons.edit_outlined, color: iconEdit), onPressed: () => _showScheduleDialog(context, mode: DialogMode.edit, schedule: schedule), tooltip: "Sửa"),
        IconButton(icon: Icon(Icons.delete_outline, color: iconDelete), onPressed: () => _showDeleteConfirmDialog(context, schedule), tooltip: "Xóa"),
      ],
      ),
      ),
    ],
    );
  }

  void _showScheduleDialog(BuildContext context, {required DialogMode mode, Schedule? schedule}) {
    // ... (Keep logic)
    showDialog(context: context, builder: (BuildContext dialogContext) {
      return _ScheduleDialog(mode: mode, schedule: schedule, apiService: _apiService,
        onSave: () {
          Navigator.of(dialogContext).pop();
          _loadSchedules(resetPage: true);
        },
      );
    },
    );
  }

  /// Hiển thị dialog Xác nhận Xóa (VERIFY SNACKBAR PLACEMENT)
  void _showDeleteConfirmDialog(BuildContext context, Schedule schedule) async {
    bool? confirmed = await showDialog<bool>( /* ... AlertDialog setup ... */
      context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), title: Text("Thông báo!"), content: Text("Bạn chắc chắn muốn xóa lịch học này?"),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text("Hủy"), style: TextButton.styleFrom(foregroundColor: Colors.grey[700], backgroundColor: Colors.grey[200])),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text("Xác nhận"), style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green)),
        ],
      );
    },
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteSchedule(schedule.id);
        _loadSchedules(resetPage: true); // Tải lại TRƯỚC khi hiển thị SnackBar

        // **** SNACKBAR CHO XÓA THÀNH CÔNG (ĐÃ ĐÚNG VỊ TRÍ) ****
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã xóa lịch học thành công!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Tùy chọn: làm cho nó nổi lên
            margin: EdgeInsets.all(10),       // Tùy chọn: thêm margin
            duration: Duration(seconds: 2),    // Tùy chọn: thời gian hiển thị
          ),
        );
        // **** KẾT THÚC SNACKBAR ****

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi xóa: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
          ),
        );
      }
    }
  }
}

// -------------------------------------------------------------
// --- _ScheduleDialog (ADD SNACKBAR IN _handleSave) ---
// -------------------------------------------------------------
class _ScheduleDialog extends StatefulWidget {
  // ... (Keep properties)
  final DialogMode mode;
  final Schedule? schedule;
  final ApiService apiService;
  final VoidCallback onSave;
  const _ScheduleDialog({ Key? key, required this.mode, this.schedule, required this.apiService, required this.onSave }) : super(key: key);

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  // ... (Keep form key, state variables, futures)
  final _formKey = GlobalKey<FormState>();
  int? _selectedAssignmentId;
  int? _selectedRoomId;
  late TextEditingController _sessionController;
  DateTime? _selectedDate;
  bool _isReadOnly = false;
  bool _isLoading = false;
  late Future<List<ClassCourseAssignment>> _assignmentsFuture;
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    // ... (Keep initState logic)
    super.initState();
    _assignmentsFuture = widget.apiService.fetchClassCourseAssignments();
    _roomsFuture = widget.apiService.fetchRooms();
    if (widget.mode == DialogMode.edit || widget.mode == DialogMode.view) {
      _selectedAssignmentId = widget.schedule?.classCourseAssignmentId;
      _selectedRoomId = widget.schedule?.roomId;
      _sessionController = TextEditingController(text: widget.schedule?.session ?? '');
      _selectedDate = widget.schedule?.date;
    } else {
      _sessionController = TextEditingController();
      _selectedDate = DateTime.now();
    }
    _isReadOnly = widget.mode == DialogMode.view;
  }

  @override
  void dispose() {
    // ... (Keep dispose logic)
    _sessionController.dispose();
    super.dispose();
  }

  /// Xử lý khi nhấn nút Lưu (Thêm/Sửa) - THÊM SNACKBAR
  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAssignmentId == null || _selectedRoomId == null || _selectedDate == null) {
        // ... (Keep validation check)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng chọn đầy đủ thông tin"), backgroundColor: Colors.red));
        return;
      }

      setState(() => _isLoading = true);
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final data = {
        'class_course_assignment_id': _selectedAssignmentId, 'room_id': _selectedRoomId,
        'date': formattedDate, 'session': _sessionController.text,
      };

      try {
        String successMessage; // Biến lưu thông báo thành công
        if (widget.mode == DialogMode.add) {
          await widget.apiService.createSchedule(data);
          successMessage = "Thêm lịch học thành công!"; // <-- Thông báo cho Thêm
        } else { // Must be DialogMode.edit
          await widget.apiService.updateSchedule(widget.schedule!.id, data);
          successMessage = "Cập nhật lịch học thành công!"; // <-- Thông báo cho Sửa
        }

        // **** SNACKBAR CHO THÊM/SỬA THÀNH CÔNG (THÊM VÀO ĐÂY) ****
        // Hiển thị SnackBar TRƯỚC khi gọi onSave (để context còn hợp lệ)
        if (mounted) { // Kiểm tra `mounted` trước khi dùng context trong async gap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating, // Tùy chọn
              margin: EdgeInsets.all(10),          // Tùy chọn
              duration: Duration(seconds: 2),       // Tùy chọn
            ),
          );
        }
        // **** KẾT THÚC SNACKBAR ****

        widget.onSave(); // Gọi callback SAU KHI hiển thị SnackBar

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi lưu: $e"), backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(10)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ... (Keep _getTitle, _getActions, build, _buildAssignmentDropdown, _buildRoomDropdown, _buildDatePicker, _buildTextField, _inputDecoration)
  String _getTitle() { /* ... */ switch (widget.mode) { case DialogMode.add: return "Thêm lịch học"; case DialogMode.edit: return "Sửa thông tin lịch học"; case DialogMode.view: return "Xem thông tin lịch học"; } }
  List<Widget> _getActions() { /* ... */ if (_isLoading) { return [CircularProgressIndicator()]; } if (widget.mode == DialogMode.view) { return [ TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Xác nhận"), style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green)), ]; } return [ TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("Hủy"), style: TextButton.styleFrom(foregroundColor: Colors.grey[700], backgroundColor: Colors.grey[200])), TextButton(onPressed: _handleSave, child: Text("Lưu"), style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green)), ]; }
  @override Widget build(BuildContext context) { /* ... Keep AlertDialog structure ... */ Color headerColor = const Color(0xFF4FA8E1); return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), titlePadding: EdgeInsets.zero, title: Container( padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), decoration: BoxDecoration( color: headerColor, borderRadius: BorderRadius.only( topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0), ) ), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( _getTitle(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), ), IconButton( icon: Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop(), padding: EdgeInsets.zero, constraints: BoxConstraints(), ), ], ), ), content: Container( width: MediaQuery.of(context).size.width * 0.7, constraints: BoxConstraints(maxWidth: 800), child: Form( key: _formKey, child: SingleChildScrollView( padding: const EdgeInsets.only(top: 20.0, bottom: 10.0), child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ _buildAssignmentDropdown(), SizedBox(height: 16), _buildRoomDropdown(), SizedBox(height: 16), _buildDatePicker(context), SizedBox(height: 16), _buildTextField("Ca học (ví dụ: 1-3)", _sessionController), ], ), ), ), ), actionsPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), actionsAlignment: MainAxisAlignment.end, actions: _getActions(), ); }
  /// Helper build Dropdown Phân công (ĐÃ SỬA ĐỂ LỌC TRÙNG)
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
          // --- BẮT ĐẦU LỌC TRÙNG ---
          final uniqueAssignments = <String, int>{}; // Map<DisplayName, ID>
          for (var assignment in snapshot.data!) {
            // Chỉ thêm nếu display name chưa tồn tại trong map
            uniqueAssignments.putIfAbsent(assignment.displayName, () => assignment.id);
          }

          // Tạo danh sách item cho dropdown từ map đã lọc
          final dropdownItems = uniqueAssignments.entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.value, // ID là value
              child: Text(entry.key, overflow: TextOverflow.ellipsis), // DisplayName là text hiển thị
            );
          }).toList();
          // --- KẾT THÚC LỌC TRÙNG ---

          content = DropdownButtonFormField<int>(
            // Kiểm tra xem ID đang chọn có còn tồn tại trong danh sách đã lọc không
            value: uniqueAssignments.containsValue(_selectedAssignmentId) ? _selectedAssignmentId : null,
            hint: Text("Chọn GV - Môn - Lớp *"),
            isExpanded: true,
            decoration: _inputDecoration(""),
            items: dropdownItems, // Sử dụng danh sách đã lọc
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
  Widget _buildRoomDropdown() { /* ... Keep FutureBuilder logic ... */ return FutureBuilder<List<Room>>( future: _roomsFuture, builder: (context, snapshot) { Widget content; if (snapshot.connectionState == ConnectionState.waiting) { content = Center(child: CircularProgressIndicator(strokeWidth: 2)); } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) { content = Text("Lỗi tải DS phòng", style: TextStyle(color: Colors.red)); } else { content = DropdownButtonFormField<int>( value: _selectedRoomId, hint: Text("Chọn phòng học *"), decoration: _inputDecoration(""), items: snapshot.data!.map((room) => DropdownMenuItem<int>( value: room.id, child: Text(room.name), )).toList(), onChanged: _isReadOnly ? null : (value) => setState(() => _selectedRoomId = value), validator: (value) => value == null ? 'Vui lòng chọn' : null, ); } return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("Phòng học *", style: TextStyle(color: Colors.grey[700], fontSize: 12)), SizedBox(height: 4), content, ], ); }, ); }
  Widget _buildDatePicker(BuildContext context) { /* ... Keep Column and TextFormField logic ... */ return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("Ngày học *", style: TextStyle(color: Colors.grey[700], fontSize: 12)), SizedBox(height: 4), TextFormField( readOnly: true, controller: TextEditingController( text: _selectedDate == null ? '' : DateFormat('dd/MM/yyyy').format(_selectedDate!) ), decoration: _inputDecoration("").copyWith( suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]), hintText: "Chọn ngày học *" ), onTap: _isReadOnly ? null : () async { final DateTime? picked = await showDatePicker( context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030), ); if (picked != null && picked != _selectedDate) { setState(() => _selectedDate = picked); } }, validator: (value) => _selectedDate == null ? 'Vui lòng chọn ngày' : null, ), ], ); }
  Widget _buildTextField(String label, TextEditingController controller) { /* ... Keep TextFormField logic ... */ return TextFormField( controller: controller, readOnly: _isReadOnly, decoration: _inputDecoration(label), validator: (value) => (value == null || value.isEmpty) ? 'Vui lòng nhập $label' : null, ); }
  InputDecoration _inputDecoration(String label) { /* ... Keep InputDecoration logic ... */ return InputDecoration( labelText: label.isNotEmpty ? "$label *" : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.0)), filled: _isReadOnly, fillColor: _isReadOnly ? Colors.grey[100] : null, contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0) ); }

} // End of _ScheduleDialogState