import 'package:flutter/material.dart';
import '../api_service.dart';       // 👈 THÊM
import '../table/home_summary.dart';// 👈 THÊM
import '../table/user.dart';        // 👈 THÊM

// 👇 THAY ĐỔI: Chuyển thành StatefulWidget
class DashboardContent extends StatefulWidget {
  // 👈 THÊM: Nhận user từ HomeScreen
  final User user;
  const DashboardContent({Key? key, required this.user}) : super(key: key);

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final Color tluBlue = const Color(0xFF005A9C);

  // 👇 THÊM: State để gọi API
  late Future<HomeSummary> _summaryFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // 👈 THÊM: Gọi API khi widget được tạo, dùng ID của user
    _summaryFuture = _apiService.fetchHomeSummary(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    // 👇 THÊM: Dùng FutureBuilder để xử lý các trạng thái
    return FutureBuilder<HomeSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {

        // 1. Trạng thái Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // 2. Trạng thái Lỗi
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi khi tải dữ liệu: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // 3. Trạng thái Không có dữ liệu
        if (!snapshot.hasData) {
          return Center(child: Text('Không có dữ liệu trang chủ.'));
        }

        // 4. Trạng thái Thành công: Lấy dữ liệu
        final homeData = snapshot.data!;

        // Trả về UI chính (lấy từ hàm build() cũ của bạn)
        // Dùng `homeData` để điền dữ liệu
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề "Trang chủ" (cho layout desktop)
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

              // --- 👇 THAY ĐỔI: Dùng dữ liệu API ---
              // API của PĐT trả về 'số tiết', không phải 'số người dùng'.
              // Chúng ta sẽ hiển thị dữ liệu API nhận được.
              Wrap(
                spacing: 24.0,
                runSpacing: 24.0,
                children: [
                  _buildStatCard(
                      "Số tiết hôm nay",      // Tiêu đề ĐÚNG
                      homeData.summary.todayLessons.toString(), // Dữ liệu API
                      Icons.today_outlined,
                      Colors.blue
                  ),
                  _buildStatCard(
                      "Tổng số tiết tuần này", // Tiêu đề ĐÚNG
                      homeData.summary.weekLessons.toString(), // Dữ liệu API
                      Icons.calendar_view_week_outlined,
                      Colors.green
                  ),
                  _buildStatCard(
                      "Tỷ lệ hoàn thành", // (Dữ liệu giả từ API)
                      '${homeData.summary.completionPercent.toStringAsFixed(1)}%', // Dữ liệu API
                      Icons.pie_chart_outline,
                      Colors.orange
                  ),
                ],
              ),
              // --- 👆 KẾT THÚC THAY ĐỔI ---

              SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Lịch dạy hôm nay", // (Đây là lịch của PĐT)
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    // Lấy ngày hôm nay
                    "Thứ ${DateTime.now().weekday + 1}, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // --- 👇 THAY ĐỔI: Dùng dữ liệu API ---
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
                    // Truyền đối tượng schedule vào hàm build
                    return _buildScheduleCard(schedule);
                  }).toList(),
                )
              // --- 👆 KẾT THÚC THAY ĐỔI ---
            ],
          ),
        );
      },
    );
  }

  // --- (Hàm _buildStatCard giữ nguyên) ---
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

  // --- 👇 THAY ĐỔI: Hàm này giờ nhận 1 đối tượng TodaySchedule ---
  Widget _buildScheduleCard(TodaySchedule schedule) {
    // API `home-summary` không trả về tên giảng viên
    // (Vì đang xem bằng tài khoản PĐT).

    return Container(
      width: 430, // Chiều rộng thẻ
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
          // Tiêu đề (Tên môn học)
          Text(schedule.title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: tluBlue)),
          Divider(height: 24, color: Colors.grey.shade200),

          _buildScheduleRow(
            schedule.courseCode, // Mã lớp
            schedule.timeRange, // Giờ
            schedule.location,  // Phòng
          ),
        ],
      ),
    );
  }

  // --- 👇 THAY ĐỔI: Đơn giản hóa hàm này ---
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