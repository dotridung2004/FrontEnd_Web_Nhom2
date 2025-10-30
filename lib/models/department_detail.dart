import 'package:flutter/material.dart';
// import '../api_service.dart'; // Sẽ dùng sau
// import '../models/department_detail.dart'; // Sẽ dùng sau

// --- DỮ LIỆU GIẢ (MOCK DATA) ---

class MockTeacherInfo {
  final String id;
  final String code;
  final String name;
  final String email;
  final String phone;
  MockTeacherInfo(this.id, this.code, this.name, this.email, this.phone);
}

class MockMajorInfo {
  final String id;
  final String name;
  MockMajorInfo(this.id, this.name);
}

// 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
// Thêm lại MockDivisionInfo
class MockDivisionInfo {
  final String id;
  final String code;
  final String name;
  final String description;
  MockDivisionInfo(this.id, this.code, this.name, this.description);
}

// Dữ liệu chi tiết của 1 Khoa (Thêm lại Bộ môn)
class MockDepartmentDetail {
  final String code = 'CNTT';
  final String name = 'Công nghệ thông tin';
  final int teacherCount = 4;
  final int divisionCount = 3; // (Thêm lại)
  final String description =
      'Khoa Công nghệ Thông tin là nơi đào tạo và nghiên cứu các lĩnh vực liên quan đến máy tính, phần mềm, hệ thống thông tin và trí tuệ nhân tạo...';

  final List<MockTeacherInfo> teachers = [
    MockTeacherInfo(
        '1', 'GV001', 'Nguyễn Văn A', 'nguyenvana@tlu.edu.vn', '0123456789'),
    MockTeacherInfo(
        '2', 'GV002', 'Nguyễn Văn B', 'nguyenvanb@tlu.edu.vn', '0123434569'),
    MockTeacherInfo(
        '3', 'GV003', 'Trần Thị C', 'tranthic@tlu.edu.vn', '0123434569'),
    MockTeacherInfo(
        '4', 'GV004', 'Đỗ Văn An', 'dovana@tlu.edu.vn', '0123434569'),
  ];

  final List<MockMajorInfo> majors = [
    MockMajorInfo('1', 'Hệ thống thông tin (HTTT)'),
    MockMajorInfo('2', 'Kỹ thuật phần mềm (KTPM)'),
    MockMajorInfo('3', 'Trí tuệ nhân tạo (TTNT)'),
    MockMajorInfo('4', 'An ninh mạng (ANM)'),
  ];

  // (Thêm lại danh sách bộ môn)
  final List<MockDivisionInfo> divisions = [
    MockDivisionInfo('1', 'CNPM', 'Công nghệ phần mềm', 'Bộ môn CNPM'),
    MockDivisionInfo('2', 'TTNT', 'Trí tuệ nhân tạo', 'Bộ môn TTNT'),
    MockDivisionInfo('3', 'HTTT', 'Hệ thống thông tin', 'Bộ môn HTTT'),
  ];
}
// 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
// --- HẾT DỮ LIỆU GIẢ ---

class DepartmentDetailScreen extends StatefulWidget {
  final int departmentId; // ID này sẽ dùng để gọi API

  const DepartmentDetailScreen({
    Key? key,
    required this.departmentId,
  }) : super(key: key);

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  final Color tluBlue = const Color(0xFF005A9C);
  // final ApiService _apiService = ApiService(); // Sẽ dùng sau

  // State
  late MockDepartmentDetail _departmentDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; });

    // TODO: Gọi API bằng widget.departmentId
    // final data = await _apiService.fetchDepartmentDetails(widget.departmentId);

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _departmentDetail = MockDepartmentDetail();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('THÔNG TIN KHOA'),
        backgroundColor: tluBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Thông tin cơ bản'),
            _buildBasicInfo(_departmentDetail),
            const SizedBox(height: 24),

            _buildSectionTitle(
                'Danh sách giảng viên (${_departmentDetail.teachers.length})'),
            _buildTeachersTable(_departmentDetail.teachers),
            const SizedBox(height: 24),

            _buildSectionTitle(
                'Danh sách ngành (${_departmentDetail.majors.length})'),
            _buildMajorsList(_departmentDetail.majors),
            const SizedBox(height: 24),

            // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
            _buildSectionTitle(
                'Danh sách bộ môn (${_departmentDetail.divisions.length})'),
            _buildDivisionsTable(_departmentDetail.divisions),
            // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Quay lại', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  // --- CÁC WIDGET HELPER ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue),
      ),
    );
  }

  Widget _buildBasicInfo(MockDepartmentDetail detail) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyTextField('Mã khoa:', detail.code)),
            const SizedBox(width: 16),
            Expanded(child: _buildReadOnlyTextField('Tên khoa:', detail.name)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildReadOnlyTextField(
                'Số lượng giảng viên:', detail.teacherCount.toString())),
            const SizedBox(width: 16),
            // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
            Expanded(child: _buildReadOnlyTextField(
                'Số lượng bộ môn:', detail.divisionCount.toString())),
            // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
          ],
        ),
        const SizedBox(height: 16),
        _buildReadOnlyTextField('Mô tả:', detail.description, maxLines: 4),
      ],
    );
  }

  Widget _buildTeachersTable(List<MockTeacherInfo> teachers) {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columns: [
              DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mã giảng viên', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Họ tên', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(teachers.length, (index) {
              final teacher = teachers[index];
              return DataRow(cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(teacher.code)),
                DataCell(Text(teacher.name)),
                DataCell(Text(teacher.email)),
                DataCell(Text(teacher.phone)),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMajorsList(List<MockMajorInfo> majors) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: majors.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(majors[index].name),
            leading: Text((index + 1).toString()),
          );
        },
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey.shade300),
      ),
    );
  }

  // 👇 **** BẮT ĐẦU SỬA ĐỔI **** 👇
  // (Thêm lại hàm build bảng bộ môn)
  Widget _buildDivisionsTable(List<MockDivisionInfo> divisions) {
    return Container(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.7),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columns: [
              DataColumn(label: Text('STT', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mã bộ môn', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tên bộ môn', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(divisions.length, (index) {
              final division = divisions[index];
              return DataRow(cells: [
                DataCell(Text((index + 1).toString())),
                DataCell(Text(division.code)),
                DataCell(Text(division.name)),
                DataCell(Text(division.description)),
              ]);
            }),
          ),
        ),
      ),
    );
  }
  // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

  Widget _buildReadOnlyTextField(String label, String value, {int? maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: (maxLines ?? 0) > 1 ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
}