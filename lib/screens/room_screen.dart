// lib/screens/room_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/room.dart';
import '../models/room_detail.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({Key? key}) : super(key: key);

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final Color tluBlue = const Color(0xFF005A9C);
  final ApiService _apiService = ApiService();

  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  int _rowsPerPage = 10;
  int _currentPage = 1;
  int _totalPages = 1;
  List<Room> _paginatedRooms = [];

  int _sortColumnIndex = -1;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _searchController.addListener(_filterRooms);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final rooms = await _apiService.fetchRooms();
      setState(() {
        _allRooms = rooms;
        _isLoading = false;
        _errorMessage = '';
      });
      _filterRooms();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _filterRooms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _currentPage = 1;
      _filteredRooms = _allRooms.where((room) {
        return room.name.toLowerCase().contains(query) ||
            room.building.toLowerCase().contains(query) ||
            room.type.toLowerCase().contains(query);
      }).toList();
      _sortAndPaginateRooms();
    });
  }

  void _sortAndPaginateRooms() {
    // (SỬA) Không cần sắp xếp ở client vì server đã sắp xếp
    // _filteredRooms.sort(...);

    _totalPages = (_filteredRooms.length / _rowsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
    _currentPage = min(_currentPage, _totalPages);
    final int startIndex = (_currentPage - 1) * _rowsPerPage;
    final int endIndex = min(startIndex + _rowsPerPage, _filteredRooms.length);
    _paginatedRooms = _filteredRooms.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
      _sortAndPaginateRooms();
    });
  }

  void _firstPage() => _goToPage(1);
  void _prevPage() => _goToPage(_currentPage - 1);
  void _nextPage() => _goToPage(_currentPage + 1);
  void _lastPage() => _goToPage(_totalPages);

  // ============ Các hàm Helper ============
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // ============ Hàm build Dialog tùy chỉnh (Giống Ngành học) ============
  Widget _buildCustomDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: "Đóng",
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: content,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Hàm _showRoomDialog (Add/Edit) ============

  void _showAddDialog() => _showRoomDialog(null);
  void _showEditDialog(Room room) => _showRoomDialog(room);

  void _showRoomDialog(Room? room) {
    final _formKey = GlobalKey<FormState>();
    final isEditing = room != null;
    final title = isEditing ? 'Chỉnh sửa thông tin phòng học' : 'Thêm phòng học mới';

    final _nameController = TextEditingController(text: room?.name ?? '');
    final _buildingController = TextEditingController(text: room?.building ?? '');
    final _floorController = TextEditingController(text: room?.floor.toString() ?? '');
    final _capacityController = TextEditingController(text: room?.capacity.toString() ?? '');
    final _descriptionController = TextEditingController(text: room?.description ?? '');

    String? _selectedRoomType = room?.type;
    String? _selectedStatus = room?.status;

    final List<String> _roomTypes = ['Lí thuyết', 'Thực hành'];
    final List<String> _statuses = ['Hoạt động', 'Bảo trì'];

    bool _isSubmitting = false;

    Future<void> _submitForm(Function setDialogState) async {
      if (_formKey.currentState!.validate()) {
        setDialogState(() {
          _isSubmitting = true;
        });

        final data = {
          'name': _nameController.text,
          'building': _buildingController.text,
          'floor': int.tryParse(_floorController.text) ?? 0,
          'capacity': int.tryParse(_capacityController.text) ?? 0,
          'room_type': _selectedRoomType,
          'status': _selectedStatus,
          'description': _descriptionController.text,
        };

        FocusScope.of(context).unfocus();

        try {
          if (!isEditing) {
            // --- BẮT ĐẦU SỬA ---
            final newRoom = await _apiService.createRoom(data);
            _showSuccessSnackBar(context, 'Thêm phòng học thành công!');

            setState(() {
              _allRooms.insert(0, newRoom); // Thêm vào đầu danh sách
              _filterRooms(); // Lọc và phân trang lại
            });
            // --- KẾT THÚC SỬA ---
          } else {
            // --- BẮT ĐẦU SỬA ---
            final updatedRoom = await _apiService.updateRoom(room!.id, data);
            _showSuccessSnackBar(context, 'Cập nhật phòng học thành công!');

            setState(() {
              _allRooms.removeWhere((r) => r.id == updatedRoom.id); // Xóa
              _allRooms.insert(0, updatedRoom); // Thêm vào đầu
              _filterRooms(); // Lọc và phân trang lại
            });
            // --- KẾT THÚC SỬA ---
          }
          Navigator.of(context).pop(); // Đóng dialog
        } catch (e) {
          _showErrorSnackBar(context, 'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}');
          setDialogState(() {
            _isSubmitting = false;
          });
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {

            return _buildCustomDialog(
              context: context,
              title: title,
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTextField(
                          _nameController,
                          'Mã phòng',
                          hintText: 'Nhập mã phòng',
                          isRequired: true,
                        )),
                        SizedBox(width: 20),
                        Expanded(child: _buildTextField(
                          _buildingController,
                          'Tòa nhà',
                          hintText: 'Nhập tòa nhà',
                          isRequired: true,
                        )),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTextField(
                          _floorController,
                          'Tầng',
                          hintText: 'Nhập tầng',
                          isNumber: true,
                          isRequired: true,
                        )),
                        SizedBox(width: 20),
                        Expanded(child: _buildTextField(
                          _capacityController,
                          'Sức chứa',
                          hintText: 'Nhập sức chứa',
                          isNumber: true,
                          isRequired: true,
                        )),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedRoomType,
                            items: _roomTypes,
                            label: 'Loại phòng',
                            hintText: '-- Chọn loại phòng --',
                            onChanged: (val) => setDialogState(() => _selectedRoomType = val),
                            isRequired: true,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedStatus,
                            items: _statuses,
                            label: 'Trạng thái',
                            hintText: '-- Chọn trạng thái --',
                            onChanged: (val) => setDialogState(() => _selectedStatus = val),
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      _descriptionController,
                      'Mô tả',
                      hintText: 'Nhập mô tả',
                      isRequired: false,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Text('Hủy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitForm(setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF28a745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hintText, bool isRequired = true, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? "*" : ""}',
          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tluBlue, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Vui lòng nhập $label';
            }
            if (isNumber && (value != null && value.isNotEmpty) && int.tryParse(value) == null) {
              return 'Vui lòng nhập số hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    String? hintText,
    required ValueChanged<String?> onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ${isRequired ? "*" : ""}',
          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: tluBlue, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => (value == null) ? 'Vui lòng chọn $label' : null,
        ),
      ],
    );
  }

  // ============ Cập nhật hàm _showDeleteDialog ============

  void _showDeleteDialog(Room room) {
    bool _isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Center(child: Text('Thông báo!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
              content: Text('Bạn chắc chắn muốn xóa phòng học "${room.name}"?', textAlign: TextAlign.center),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              actions: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                    child: Text('Hủy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : () async {
                      setDialogState(() {
                        _isDeleting = true;
                      });

                      try {
                        await _apiService.deleteRoom(room.id);
                        Navigator.of(context).pop();
                        _showSuccessSnackBar(context, 'Xóa phòng học thành công!');

                        // (SỬA) Cập nhật UI ngay lập tức
                        setState(() {
                          _allRooms.removeWhere((r) => r.id == room.id);
                          _filterRooms();
                        });

                      } catch (e) {
                        _showErrorSnackBar(context, 'Lỗi: ${e.toString().replaceFirst('Exception: ', '')}');
                        setDialogState(() {
                          _isDeleting = false;
                        });
                      }
                    },
                    child: _isDeleting
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text('Xác nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF28a745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============ Cập nhật hàm _showViewDialog ============

  void _showViewDialog(Room room) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildCustomDialog(
          context: context,
          title: 'Thông Tin Phòng Học',
          content: FutureBuilder<RoomDetail>(
            future: _apiService.fetchRoomDetails(room.id),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: 300,
                  child: Center(
                    child: Text('Lỗi tải dữ liệu: ${snapshot.error.toString().replaceFirst("Exception: ", "")}'),
                  ),
                );
              }

              final roomDetail = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin cơ bản',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tluBlue),
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildReadOnlyField('Mã phòng:', roomDetail.name)),
                      SizedBox(width: 20),
                      Expanded(child: _buildReadOnlyField('Tòa nhà:', roomDetail.building)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildReadOnlyField('Tầng:', roomDetail.floor.toString())),
                      SizedBox(width: 20),
                      Expanded(child: _buildReadOnlyField('Sức chứa:', roomDetail.capacity.toString())),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildReadOnlyField('Loại phòng:', roomDetail.type)),
                      SizedBox(width: 20),
                      Expanded(child: _buildReadOnlyField('Trạng thái:', roomDetail.status)),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildReadOnlyField('Mô tả:', roomDetail.description.isEmpty ? '(Không có)' : roomDetail.description, maxLines: 3),
                ],
              );
            },
          ),

          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tluBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          readOnly: true,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // ============ Build Widgets (Giao diện chính) ============
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: _isLoading
                ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator()))
                : _errorMessage.isNotEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(_errorMessage, style: TextStyle(color: Colors.red))))
                : Column(
              children: [
                _buildDataTable(),
              ],
            ),
          ),
          if (!_isLoading && _errorMessage.isEmpty)
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _showAddDialog,
          icon: Icon(Icons.add, color: Colors.white, size: 20),
          label: Text("Thêm phòng học", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
              hintText: "Tìm kiếm (Mã, Tòa nhà...)",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: Colors.grey.shade300)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(tluBlue),
              columns: _buildDataColumns(),
              rows: _buildDataRows(),
              dataRowHeight: 56.0,
              headingRowHeight: 56.0,
            ),
          ),
        );
      },
    );
  }

  List<DataColumn> _buildDataColumns() {
    final TextStyle headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    return [
      DataColumn(label: Text('STT', style: headerStyle)),
      DataColumn(label: Text('Mã phòng', style: headerStyle)),
      DataColumn(label: Text('Tòa nhà', style: headerStyle)),
      DataColumn(label: Text('Tầng', style: headerStyle)),
      DataColumn(label: Text('Sức chứa', style: headerStyle)),
      DataColumn(label: Text('Loại phòng', style: headerStyle)),
      DataColumn(label: Text('Trạng thái', style: headerStyle)),
      DataColumn(label: Text('Thao tác', style: headerStyle)),
    ];
  }

  List<DataRow> _buildDataRows() {
    return _paginatedRooms.asMap().entries.map((entry) {
      final int index = entry.key;
      final Room room = entry.value;
      final int stt = (_currentPage - 1) * _rowsPerPage + index + 1;

      return DataRow(
        cells: [
          DataCell(Text(stt.toString())),
          DataCell(Text(room.name)),
          DataCell(Text(room.building)),
          DataCell(Text(room.floor.toString())),
          DataCell(Text(room.capacity.toString())),
          DataCell(Text(room.type)),
          DataCell(Text(room.status)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.info_outline, color: Colors.blue), onPressed: () => _showViewDialog(room), tooltip: "Xem"),
                IconButton(icon: Icon(Icons.edit_outlined, color: Colors.green), onPressed: () => _showEditDialog(room), tooltip: "Sửa"),
                IconButton(icon: Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _showDeleteDialog(room), tooltip: "Xóa"),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang $_currentPage / $_totalPages (Tổng: ${_filteredRooms.length})',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.first_page),
                onPressed: _currentPage == 1 ? null : _firstPage,
                tooltip: 'Trang đầu',
              ),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage == 1 ? null : _prevPage,
                tooltip: 'Trang trước',
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _currentPage == _totalPages ? null : _nextPage,
                tooltip: 'Trang sau',
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: _currentPage == _totalPages ? null : _lastPage,
                tooltip: 'Trang cuối',
              ),
            ],
          ),
        ],
      ),
    );
  }
}