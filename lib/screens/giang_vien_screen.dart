import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../api_service.dart'; // Đảm bảo đường dẫn này chính xác
import '../models/lecturer.dart'; // Đảm bảo đường dẫn này chính xác

class GiangVienScreen extends StatefulWidget {
  const GiangVienScreen({Key? key}) : super(key: key);

  @override
  State<GiangVienScreen> createState() => _GiangVienScreenState();
}

class _GiangVienScreenState extends State<GiangVienScreen> {
  // --- State and Colors ---
  static const Color tluBlue = Color(0xFF005A9C);
  static const Color iconView = Colors.blue;
  static const Color iconEdit = Colors.green;
  static const Color iconDelete = Colors.red;
  static const Color screenBg = Color(0xFFF0F4F8);

  final ApiService _apiService = ApiService();
  late Future<List<Lecturer>> _lecturersFuture;

  final List<String> _departments = ['Công nghệ thông tin', 'Công trình', 'Cơ khí', 'Kinh tế'];
  String? _selectedDepartment;
  final TextEditingController _searchController = TextEditingController();

  List<Lecturer> _allLecturers = [];
  List<Lecturer> _filteredLecturers = [];

  // --- State cho phân trang ---
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  // --- 👇 1. THÊM HÀM HELPER NÀY ---
  void _goToPage(int page) {
    // Đảm bảo trang nằm trong giới hạn hợp lệ
    final int totalItems = _filteredLecturers.length;
    final int totalPages = _rowsPerPage > 0 ? (totalItems / _rowsPerPage).ceil() : 0;

    if (page < 1) page = 1;
    if (page > totalPages && totalPages > 0) page = totalPages;

    setState(() {
      _currentPage = page;
    });
  }
  // --- Hết phần thêm ---

  @override
  void initState() {
    super.initState();
    _loadLecturers();
    _searchController.addListener(_filterData);
  }

  void _loadLecturers() {
    setState(() {
      _lecturersFuture = _apiService.fetchLecturers();
    });
    _lecturersFuture.then((data) {
      if (mounted) {
        // Sắp xếp danh sách để mục mới nhất (ID cao nhất) lên đầu
        data.sort((a, b) => b.id.compareTo(a.id));

        setState(() {
          _allLecturers = data;
          _filterData(); // Áp dụng bộ lọc để cập nhật UI
        });
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $error'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLecturers = _allLecturers.where((lecturer) {
        final departmentMatch = _selectedDepartment == null || lecturer.departmentName == _selectedDepartment;
        final searchMatch = lecturer.fullName.toLowerCase().contains(query) ||
            lecturer.email.toLowerCase().contains(query);
        return departmentMatch && searchMatch;
      }).toList();
      _currentPage = 1; // Reset về trang 1 mỗi khi lọc
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterData);
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC CHO THÊM / SỬA / XÓA ---
  // (Giữ nguyên không đổi)
  void _onSaveLecturer(bool isEditing, Lecturer lecturer, String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (isEditing) {
        await _apiService.updateLecturer(lecturer.id, lecturer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: Colors.blue),
        );
      } else {
        final data = lecturer.toJson();
        data['password'] = password;
        await _apiService.addLecturer(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm giảng viên thành công!'), backgroundColor: Colors.green),
        );
      }
      Navigator.of(context).pop(); // Đóng dialog loading
      Navigator.of(context).pop(); // Đóng dialog form
      _loadLecturers(); // Tải lại dữ liệu để thấy thay đổi và sắp xếp
    } catch (e) {
      Navigator.of(context).pop(); // Đóng dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _deleteLecturer(int id) async {
    try {
      await _apiService.deleteLecturer(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa giảng viên thành công!'), backgroundColor: Colors.red),
      );
      _loadLecturers(); // Tải lại dữ liệu sau khi xóa
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteConfirmDialog(Lecturer lecturer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa giảng viên "${lecturer.fullName}" không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteLecturer(lecturer.id);
              },
            ),
          ],
        );
      },
    );
  }

  // --- CÁC DIALOG HIỂN THỊ ---
  // (Giữ nguyên không đổi)
  void _showLecturerFormDialog({Lecturer? lecturer}) {
    final isEditing = lecturer != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: isEditing ? lecturer.fullName : '');
    final dobController = TextEditingController(text: isEditing ? lecturer.dob : '');
    final emailController = TextEditingController(text: isEditing ? lecturer.email : '');
    final phoneController = TextEditingController(text: isEditing ? lecturer.phoneNumber : '');

    String? selectedDepartment = (isEditing && _departments.contains(lecturer.departmentName))
        ? lecturer.departmentName
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final dialogContentBgColor = Color(0xFFF5F5F5);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: SizedBox(
                width: 800,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
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
                              isEditing ? 'Sửa thông tin giảng viên' : 'Thêm giảng viên',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: dialogContentBgColor,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTextField(
                                            label: 'Tên giảng viên',
                                            controller: nameController,
                                            hint: 'Nhập tên giảng viên',
                                          ),
                                          const SizedBox(height: 20),
                                          _buildDatePickerField(context, dobController),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildTextField(
                                            label: 'Email',
                                            controller: emailController,
                                            hint: 'Nhập email',
                                            keyboardType: TextInputType.emailAddress,
                                            enabled: !isEditing,
                                          ),
                                          const SizedBox(height: 20),
                                          _buildTextField(
                                            label: 'Số điện thoại',
                                            controller: phoneController,
                                            hint: 'Nhập số điện thoại',
                                            keyboardType: TextInputType.phone,
                                          ),
                                          const SizedBox(height: 20),
                                          _buildDepartmentDropdown(
                                            selectedValue: selectedDepartment,
                                            onChanged: (value) {
                                              setDialogState(() {
                                                selectedDepartment = value;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
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
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          final departmentId = _departments.indexOf(selectedDepartment!) + 1;

                                          final newLecturer = Lecturer(
                                            id: isEditing ? lecturer.id : 0,
                                            departmentId: departmentId,
                                            fullName: nameController.text,
                                            email: emailController.text,
                                            dob: dobController.text,
                                            phoneNumber: phoneController.text,
                                            departmentName: selectedDepartment!,
                                          );

                                          _onSaveLecturer(isEditing, newLecturer, '123456');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLecturerDetailsDialog(Lecturer lecturer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: SizedBox(
            width: 800,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: tluBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Xem thông tin giảng viên',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildInfoField(label: 'Tên giảng viên', value: lecturer.fullName),
                                const SizedBox(height: 20),
                                _buildInfoField(label: 'Ngày sinh', value: lecturer.dob ?? 'N/A'),
                                const SizedBox(height: 20),
                                _buildInfoField(label: 'Khoa', value: lecturer.departmentName),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildInfoField(label: 'Email', value: lecturer.email),
                                const SizedBox(height: 20),
                                _buildInfoField(label: 'Số điện thoại', value: lecturer.phoneNumber ?? 'N/A'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- CÁC WIDGET HELPER ---
  // (Giữ nguyên không đổi)
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
            children: const <TextSpan>[
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Trường này không được để trống';
            }
            if (label == 'Email' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Vui lòng nhập email hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInfoField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(BuildContext context, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Ngày sinh',
            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
            children: <TextSpan>[
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Chọn ngày sinh',
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
              controller.text = formattedDate;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn ngày sinh';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown({
    String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Khoa',
            style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
            children: <TextSpan>[
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue,
          items: _departments.map((String department) {
            return DropdownMenuItem<String>(
              value: department,
              child: Text(department),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Chọn khoa',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value == null ? 'Vui lòng chọn khoa' : null,
        ),
      ],
    );
  }


  // --- GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    // Tính toán dữ liệu cho trang hiện tại
    final int totalItems = _filteredLecturers.length;
    final int totalPages = _rowsPerPage > 0 ? (totalItems / _rowsPerPage).ceil() : 0;
    final int startIndex = (_currentPage - 1) * _rowsPerPage;
    final int endIndex = min(startIndex + _rowsPerPage, totalItems);
    final List<Lecturer> paginatedData = _filteredLecturers.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: screenBg,
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildControls(),
          const SizedBox(height: 16),
          FutureBuilder<List<Lecturer>>(
            future: _lecturersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              if (_filteredLecturers.isEmpty) {
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
                        'Không tìm thấy giảng viên nào.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      )
                  ),
                );
              }
              // Column này bây giờ an toàn vì nó nằm trong ListView
              return Column(
                children: [
                  _buildDataTable(paginatedData),
                  const SizedBox(height: 16),

                  // --- 👇 2. SỬA DÒNG NÀY ---
                  // Truyền thêm totalItems vào
                  if (totalPages > 1) _buildPaginationControls(totalItems, totalPages),
                  // --- Hết phần sửa ---

                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _showLecturerFormDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: tluBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            minimumSize: const Size(0, 50),
          ),
          child: const Text("Thêm", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
        Row(
          children: [
            SizedBox(
              width: 250,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDepartment,
                    isExpanded: true,
                    hint: const Text("Khoa"),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text("Tất cả Khoa"),
                      ),
                      ..._departments.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDepartment = newValue;
                        _filterData();
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Tìm kiếm",
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
        ),
      ],
    );
  }

  Widget _buildDataTable(List<Lecturer> data) {
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
                    DataColumn(label: Text('Ngày sinh')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Số điện thoại')),
                    DataColumn(label: Text('Khoa')),
                    DataColumn(label: Text('Thao tác')),
                  ],
                  rows: List.generate(
                    data.length,
                        (index) {
                      final stt = (_currentPage - 1) * _rowsPerPage + index + 1;
                      return _buildDataRow(stt, data[index]);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(int index, Lecturer lecturer) {
    return DataRow(
      cells: [
        DataCell(Text(index.toString())),
        DataCell(Text(lecturer.fullName)),
        DataCell(Text(lecturer.dob ?? 'N/A')),
        DataCell(Text(lecturer.email)),
        DataCell(Text(lecturer.phoneNumber ?? 'N/A')),
        DataCell(Text(lecturer.departmentName)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.info_outline, color: iconView, size: 20), onPressed: () => _showLecturerDetailsDialog(lecturer), tooltip: "Xem", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.edit_outlined, color: iconEdit, size: 20), onPressed: () => _showLecturerFormDialog(lecturer: lecturer), tooltip: "Sửa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            IconButton(icon: const Icon(Icons.delete_outline, color: iconDelete, size: 20), onPressed: () => _showDeleteConfirmDialog(lecturer), tooltip: "Xóa", visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
          ],
        )),
      ],
    );
  }

  // --- 👇 3. THAY THẾ TOÀN BỘ HÀM NÀY ---
  Widget _buildPaginationControls(int totalItems, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Trang $_currentPage / $totalPages (Tổng: $totalItems)'),
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
          onPressed: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
          tooltip: 'Trang sau',
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: _currentPage < totalPages ? () => _goToPage(totalPages) : null,
          tooltip: 'Trang cuối',
        ),
      ],
    );
  }
// --- Hết phần thay thế ---
}