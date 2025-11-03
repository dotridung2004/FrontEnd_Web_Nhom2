import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_service.dart';
import '../models/pending_leave_request.dart'; // Model mới

class DuyetYeuCauScreen extends StatefulWidget {
  const DuyetYeuCauScreen({Key? key}) : super(key: key);

  @override
  State<DuyetYeuCauScreen> createState() => _DuyetYeuCauScreenState();
}

class _DuyetYeuCauScreenState extends State<DuyetYeuCauScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PendingLeaveRequest>> _requestsFuture;

  // Màu sắc
  static const Color screenBg = Color(0xFFF0F4F8);
  static const Color tluBlue = Color(0xFF005A9C);
  static const Color approveGreen = Colors.green;
  static const Color rejectRed = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture = _apiService.fetchPendingLeaveRequests();
    });
  }

  Future<void> _processRequest(int requestId, String action) async {
    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String message;
      if (action == 'approve') {
        await _apiService.approveLeaveRequest(requestId);
        message = 'Duyệt yêu cầu thành công!';
      } else {
        await _apiService.rejectLeaveRequest(requestId);
        message = 'Đã từ chối yêu cầu.';
      }

      Navigator.of(context).pop(); // Đóng dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: approveGreen),
      );
      _loadRequests(); // Tải lại danh sách
    } catch (e) {
      Navigator.of(context).pop(); // Đóng dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: rejectRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBg,
      body: FutureBuilder<List<PendingLeaveRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Lỗi từ backend (ví dụ: 'Unknown column location') sẽ hiển thị ở đây
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: rejectRed)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '🎉 Không có yêu cầu nào đang chờ duyệt.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(PendingLeaveRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.teacherName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tluBlue),
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.book_outlined, 'Môn học:', '${request.subjectName} (${request.courseCode})'),
            _buildInfoRow(Icons.calendar_today_outlined, 'Ngày nghỉ:', request.leaveDate),
            _buildInfoRow(Icons.access_time_outlined, 'Ca học:', request.session),
            //
            // ✅ SỬA LỖI 3: Sửa 'request.location' thành 'request.roomName'
            //
            _buildInfoRow(Icons.location_on_outlined, 'Phòng:', request.roomName),
            _buildInfoRow(Icons.notes_outlined, 'Lý do:', request.reason, isReason: true),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _processRequest(request.requestId, 'reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: rejectRed,
                    side: BorderSide(color: rejectRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: const Text('Từ chối'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _processRequest(request.requestId, 'approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: approveGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  child: const Text('Duyệt'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isReason = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: isReason ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontStyle: isReason ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}