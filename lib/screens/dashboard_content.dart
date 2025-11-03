// [ĐÃ SỬA LỖI TRUY CẬP DỮ LIỆU]
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../table/home_summary.dart';
import '../table/user.dart';

class DashboardContent extends StatefulWidget {
  final User user;
  const DashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final Color tluBlue = const Color(0xFF005A9C);
  late Future<HomeSummary> _summaryFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _summaryFuture = _apiService.fetchHomeSummary(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        // ... (Các trạng thái loading, error, no data) ...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải dữ liệu: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Center(child: Text('Không có dữ liệu trang chủ.'));
        }

        // 4. Trạng thái Thành công: Lấy dữ liệu
        final homeData = snapshot.data!; // homeData là 1 HomeSummary

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Tiêu đề) ...
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Text(
                    "Trang chủ",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  );
                }
                return SizedBox.shrink();
              }),
              SizedBox(height: 24),


              // --- 👇 BẮT ĐẦU SỬA LỖI ---
              // Phải truy cập thông qua 'homeData.summary'
              Wrap(
                spacing: 24.0,
                runSpacing: 24.0,
                children: [
                  _buildStatCard(
                      "Số tiết hôm nay",
                      // SỬA: Thêm .summary
                      homeData.summary.todayLessons.toString(),
                      Icons.today_outlined,
                      Colors.blue),
                  _buildStatCard(
                      "Tổng số tiết tuần này",
                      // SỬA: Thêm .summary
                      homeData.summary.weekLessons.toString(),
                      Icons.calendar_view_week_outlined,
                      Colors.green),
                  _buildStatCard(
                      "Tỷ lệ hoàn thành",
                      // SỬA: Thêm .summary
                      '${homeData.summary.completionPercent.toStringAsFixed(1)}%',
                      Icons.pie_chart_outline,
                      Colors.orange),
                ],
              ),
              // --- 👆 KẾT THÚC SỬA LỖI ---

              SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lịch dạy hôm nay",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    // Sửa logic Wday (Thứ 2=1, CN=7)
                    "Thứ ${DateTime.now().weekday == 7 ? 'Chủ nhật' : DateTime.now().weekday + 1}, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // ✅ PHẦN NÀY ĐÃ ĐÚNG
              // vì 'todaySchedules' nằm trực tiếp trong 'homeData'
              if (homeData.todaySchedules.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Không có lịch dạy hôm nay.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 24.0,
                  runSpacing: 24.0,
                  children: homeData.todaySchedules.map((schedule) {
                    return _buildScheduleCard(schedule);
                  }).toList(),
                )
            ],
          ),
        );
      },
    );
  }

  // (Hàm này không đổi)
  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(count,
                  style: TextStyle(
                      fontSize: 32,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(icon, size: 36, color: color.withOpacity(0.8)),
        ],
      ),
    );
  }

  // ✅ HÀM NÀY ĐÃ ĐÚNG (khớp với model 'TodaySchedule')
  Widget _buildScheduleCard(TodaySchedule schedule) {
    return Container(
      width: 430,
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(schedule.title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tluBlue)),
          Divider(height: 24, color: Colors.grey.shade200),
          _buildScheduleRow(
            schedule.courseCode,
            schedule.timeRange,
            schedule.roomName, // (Đã sửa từ location)
          ),
        ],
      ),
    );
  }

  // (Hàm này không đổi)
  Widget _buildScheduleRow(String className, String time, String room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(className,
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text(time, style: TextStyle(fontSize: 14, color: Colors.black54)),
            Text(room,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}