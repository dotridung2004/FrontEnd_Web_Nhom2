// lib/models/pending_leave_request.dart

class PendingLeaveRequest {
  final int requestId;
  final String teacherName;
  final String subjectName;
  final String courseCode;
  final String leaveDate; // Format 'dd/MM/yyyy'
  final String session; // Format 'Tiết 1-3'
  final String location;
  final String reason;

  PendingLeaveRequest({
    required this.requestId,
    required this.teacherName,
    required this.subjectName,
    required this.courseCode,
    required this.leaveDate,
    required this.session,
    required this.location,
    required this.reason,
  });

  factory PendingLeaveRequest.fromJson(Map<String, dynamic> json) {
    return PendingLeaveRequest(
      requestId: json['request_id'] ?? 0,
      teacherName: json['teacher_name'] ?? 'N/A',
      subjectName: json['subject_name'] ?? 'N/A',
      courseCode: json['course_code'] ?? 'N/A',
      leaveDate: json['leave_date'] ?? 'N/A',
      session: json['session'] ?? 'N/A',
      location: json['location'] ?? 'N/A',
      reason: json['reason'] ?? 'Không có lý do',
    );
  }
}