// (Đây là file tôi giả định bạn có, dựa trên màn hình DuyetYeuCauScreen)
// (Tôi đã sửa 'location' thành 'roomName' ở đây)

class PendingLeaveRequest {
  final int requestId;
  final String teacherName;
  final String subjectName;
  final String courseCode;
  final String leaveDate; // Giữ ở dạng String (dd/MM/yyyy)
  final String session;
  final String roomName; // ✅ ĐÃ SỬA (từ location)
  final String reason;

  PendingLeaveRequest({
    required this.requestId,
    required this.teacherName,
    required this.subjectName,
    required this.courseCode,
    required this.leaveDate,
    required this.session,
    required this.roomName, // ✅ ĐÃ SỬA
    required this.reason,
  });

  factory PendingLeaveRequest.fromJson(Map<String, dynamic> json) {
    return PendingLeaveRequest(
      requestId: json['request_id'] as int,
      teacherName: json['teacher_name'] as String,
      subjectName: json['subject_name'] as String,
      courseCode: json['course_code'] as String,
      leaveDate: json['leave_date'] as String,
      session: json['session'] as String,
      // ✅ SỬA LỖI: Đồng bộ với backend (sau khi backend sửa)
      roomName: json['room_name'] ?? json['location'] ?? 'N/A',
      reason: json['reason'] as String,
    );
  }
}