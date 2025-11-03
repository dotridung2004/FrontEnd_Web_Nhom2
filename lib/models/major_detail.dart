// Tên file: lib/models/major_detail.dart
// *** ĐÃ CẬP NHẬT: Thêm danh sách giảng viên, bỏ ngày tạo/cập nhật ***

// Helper class cho danh sách giảng viên (đặt cùng file cho tiện)
class TeacherSummary {
  final String maGv;
  final String hoTen;
  final String email;

  TeacherSummary({
    required this.maGv,
    required this.hoTen,
    required this.email,
  });

  factory TeacherSummary.fromJson(Map<String, dynamic> json) {
    return TeacherSummary(
      // API gửi 'ma_gv', 'ho_ten', 'email'
      maGv: json['ma_gv'] ?? 'N/A',
      hoTen: json['ho_ten'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
    );
  }
}


class MajorDetail {
  final int id;
  final String maNganh;
  final String tenNganh;
  final String? moTa;
  final int? khoaId; // ID của khoa phụ trách
  final String? tenKhoa;

  // 👇 **** SỬA ĐỔI **** 👇
  final int teacherCount;
  final List<TeacherSummary> teachers;
  // (Đã xóa createdAt và updatedAt)
  // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆

  MajorDetail({
    required this.id,
    required this.maNganh,
    required this.tenNganh,
    this.moTa,
    this.khoaId,
    this.tenKhoa,
    // 👇 **** SỬA ĐỔI **** 👇
    required this.teacherCount,
    required this.teachers,
    // (Đã xóa createdAt và updatedAt)
    // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
  });

  // (Đã xóa createdAtFormatted và updatedAtFormatted)

  factory MajorDetail.fromJson(Map<String, dynamic> json) {

    // Parse danh sách giảng viên
    var teacherList = <TeacherSummary>[];
    if (json['teachers'] != null && json['teachers'] is List) {
      teacherList = (json['teachers'] as List)
          .map((t) => TeacherSummary.fromJson(t))
          .toList();
    }

    return MajorDetail(
      id: json['id'],
      maNganh: json['ma_nganh'] ?? '',
      tenNganh: json['ten_nganh'] ?? '',
      moTa: json['mo_ta'],
      khoaId: json['khoa_id'],
      tenKhoa: json['khoa'] != null ? json['khoa']['ten_khoa'] : null,

      // 👇 **** SỬA ĐỔI **** 👇
      teacherCount: (json['teachers_count'] as num?)?.toInt() ?? 0,
      teachers: teacherList,
      // (Đã xóa createdAt và updatedAt)
      // 👆 **** KẾT THÚC SỬA ĐỔI **** 👆
    );
  }
}