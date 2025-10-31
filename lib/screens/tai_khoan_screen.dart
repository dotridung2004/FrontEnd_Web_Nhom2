// lib/screens/tai_khoan_screen.dart

import 'dart:async'; // Import thư viện async để dùng Timer
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/paginated_response.dart';
import '../api_service.dart';

class TaiKhoanScreen extends StatefulWidget {
  const TaiKhoanScreen({Key? key}) : super(key: key);

  @override
  _TaiKhoanScreenState createState() => _TaiKhoanScreenState();
}

class _TaiKhoanScreenState extends State<TaiKhoanScreen> {
  final ApiService _apiService = ApiService();

  List<AppUser> _users = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  int _fromItem = 1;
  bool _isLoading = true;

  // 👇 ================== BIẾN MỚI CHO TÌM KIẾM ================== 👇
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  // 👆 ========================================================== 👆

  @override
  void initState() {
    super.initState();
    _fetchUsersForPage(1);
  }

  // 👇 Giải phóng tài nguyên khi widget bị hủy
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsersForPage(int page) async {
    if (page < 1 || (page > _lastPage && _lastPage != 1)) return;
    if (_isLoading && _users.isNotEmpty && _searchQuery.isEmpty) return;

    setState(() { _isLoading = true; });

    try {
      // 👇 Truyền `searchQuery` vào hàm gọi API
      final PaginatedUsersResponse response = await _apiService.fetchUsers(page, searchQuery: _searchQuery);
      setState(() {
        _users = response.users;
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _totalItems = response.totalItems;
        _fromItem = response.from ?? 1;
      });
    } catch (err) {
      _showSnackBar('Lỗi: ${err.toString()}', isError: true);
    }

    setState(() { _isLoading = false; });
  }

  // 👇 ================== HÀM XỬ LÝ TÌM KIẾM ================== 👇
  void _onSearchChanged(String query) {
    // Hủy timer cũ nếu người dùng tiếp tục gõ
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Đặt timer mới, sau 500ms không gõ nữa thì mới thực hiện tìm kiếm
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query.trim()) {
        setState(() {
          _searchQuery = query.trim();
          _currentPage = 1; // Reset về trang 1 khi tìm kiếm mới
          _users = []; // Xóa dữ liệu cũ để hiển thị loading
          _isLoading = true;
        });
        _fetchUsersForPage(1);
      }
    });
  }
  // 👆 ======================================================== 👆


  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ),
    );
  }

  void _showUserDialog({AppUser? user}) {
    final bool isEditing = user != null;
    final _formKey = GlobalKey<FormState>();

    final _usernameController = TextEditingController(text: isEditing ? user!.email : '');
    final _fullNameController = TextEditingController(text: isEditing ? user!.username : '');
    final _phoneController = TextEditingController(text: '0123456789');
    final _passwordController = TextEditingController();

    final Map<String, String> roleMap = {
      'Sinh viên': 'student',
      'Giảng viên': 'teacher',
      'Phòng đào tạo': 'training_office',
      'Trưởng bộ môn': 'head_of_department',
    };

    String? _selectedRoleKey = isEditing
        ? roleMap.entries.firstWhere((e) => e.value == user!.role, orElse: () => MapEntry('', 'teacher')).value
        : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: EdgeInsets.zero,
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF0D6EBA),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Sửa tài khoản' : 'Thêm tài khoản',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                    )
                  ],
                ),
              ),
              content: SizedBox(
                width: 700,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(_usernameController, 'Tên đăng nhập (Email)'),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTextField(_fullNameController, 'Tên người dùng')),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField(_phoneController, 'Số điện thoại')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTextField(_passwordController, 'Mật khẩu', isPassword: true, hintText: isEditing ? 'Để trống nếu không đổi' : null)),
                            const SizedBox(width: 24),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedRoleKey,
                                hint: Text('-Chọn vai trò-'),
                                items: roleMap.keys.map((String key) => DropdownMenuItem<String>(value: roleMap[key], child: Text(key))).toList(),
                                onChanged: (String? newValue) => setDialogState(() => _selectedRoleKey = newValue),
                                decoration: InputDecoration(
                                  labelText: 'Vai trò *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                validator: (value) => value == null ? 'Vui lòng chọn vai trò' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nameParts = _fullNameController.text.trim().split(' ');
                      final lastName = nameParts.isNotEmpty ? nameParts.removeLast() : '';
                      final firstName = nameParts.join(' ');

                      final userData = {
                        'name': _fullNameController.text.trim(),
                        'first_name': firstName,
                        'last_name': lastName,
                        'email': _usernameController.text,
                        'phone_number': _phoneController.text,
                        'role': _selectedRoleKey,
                        'status': 'active',
                      };
                      if (_passwordController.text.isNotEmpty) {
                        userData['password'] = _passwordController.text;
                      }

                      try {
                        if (mounted) Navigator.of(context).pop();

                        if (isEditing) {
                          await _apiService.updateUser(user.id, userData);
                          _showSnackBar('Cập nhật thành công!');
                        } else {
                          await _apiService.addUser(userData);
                          _showSnackBar('Thêm mới thành công!');
                        }
                        _fetchUsersForPage(_currentPage);
                      } catch (e) {
                        _showSnackBar('Thao tác thất bại: ${e.toString()}', isError: true);
                      }
                    }
                  },
                  child: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false, String? hintText}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: '$label *',
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (isPassword && controller.text.isEmpty && hintText != null) {
          return null;
        }
        return (value == null || value.isEmpty) ? 'Không được để trống' : null;
      },
    );
  }

  void _showDeleteConfirmation(AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa tài khoản "${user.username}" không?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  if (mounted) Navigator.of(context).pop();
                  await _apiService.deleteUser(user.id);
                  _showSnackBar('Xóa thành công!');
                  if (_users.length == 1 && _currentPage > 1) {
                    _fetchUsersForPage(_currentPage - 1);
                  } else {
                    _fetchUsersForPage(_currentPage);
                  }
                } catch(e) {
                  _showSnackBar('Xóa thất bại: ${e.toString()}', isError: true);
                }
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  void _showUserDetailsDialog(AppUser user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFF0D6EBA),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thông tin chi tiết tài khoản',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                )
              ],
            ),
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildReadOnlyField('Tên đăng nhập (Email)', user.email),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildReadOnlyField('Tên người dùng', user.username)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildReadOnlyField('Số điện thoại', '0123456789')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildReadOnlyField('Mật khẩu', '********')),
                      Expanded(child: _buildReadOnlyField('Vai trò', user.role)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUserDialog(user: user);
              },
              child: const Text('Sửa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _isLoading && _users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDataTableWithPagination(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showUserDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EBA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        SizedBox(
          width: 300,
          // 👇 ================== CẬP NHẬT TEXTFIELD TÌM KIẾM ================== 👇
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên...',
              prefixIcon: const Icon(Icons.search),
              // Thêm nút xóa nhanh khi có text
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                splashRadius: 20,
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          // 👆 ================================================================= 👆
        ),
      ],
    );
  }

  Widget _buildDataTableWithPagination() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  const double headerHeight = 56;
                  if (_users.isEmpty && !_isLoading) {
                    return Center(child: Text(_searchQuery.isNotEmpty ? "Không tìm thấy kết quả" : "Không có dữ liệu"));
                  }

                  final double availableHeight = constraints.maxHeight - headerHeight;
                  final double rowHeight = availableHeight / 10;

                  return SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      dataRowHeight: rowHeight < 52 ? 52 : rowHeight,
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF0D6EBA)),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      columns: const [
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Tên người dùng')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Vai trò')),
                        DataColumn(label: Text('Ngày tạo')),
                        DataColumn(label: Text('Thao tác')),
                      ],
                      rows: _users.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        final stt = _fromItem + index;

                        return DataRow(
                          cells: [
                            DataCell(Text(stt.toString())),
                            DataCell(Text(user.username)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.role)),
                            DataCell(Text(user.creationDate)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: Colors.green),
                                    onPressed: () => _showUserDetailsDialog(user),
                                    tooltip: 'Xem chi tiết',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                    onPressed: () => _showUserDialog(user: user),
                                    tooltip: 'Sửa',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(user),
                                    tooltip: 'Xóa',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              if (_isLoading && _users.isNotEmpty)
                Container(
                  color: Colors.white.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Trang $_currentPage / $_lastPage (Tổng: $_totalItems)'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1 && !_isLoading ? () => _fetchUsersForPage(1) : null,
            tooltip: 'Trang đầu',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 && !_isLoading ? () => _fetchUsersForPage(_currentPage - 1) : null,
            tooltip: 'Trang trước',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _lastPage && !_isLoading ? () => _fetchUsersForPage(_currentPage + 1) : null,
            tooltip: 'Trang sau',
          ),
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < _lastPage && !_isLoading ? () => _fetchUsersForPage(_lastPage) : null,
            tooltip: 'Trang cuối',
          ),
        ],
      ),
    );
  }
}