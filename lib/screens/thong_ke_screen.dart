// lib/screens/thong_ke_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../api_service.dart';
import '../models/report_data.dart';

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({Key? key}) : super(key: key);

  @override
  _ThongKeScreenState createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<ReportData> _reportDataFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reportDataFuture = _apiService.fetchReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildFilterBar(),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<ReportData>(
              future: _reportDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Hiển thị lỗi một cách thân thiện hơn
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.red.shade100,
                      child: Text(
                        'Lỗi tải dữ liệu báo cáo:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Không có dữ liệu báo cáo.'));
                }

                final reportData = snapshot.data!;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(reportData.overview),
                    _buildTeachingHoursTab(reportData.teachingHours),
                    _buildAttendanceTab(reportData.attendance),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS CHÍNH ---

  Widget _buildFilterBar() {
    return Row(
      children: [
        // Dropdown cho học kỳ (ví dụ)
        Container(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: 'HK1 2024-2025',
            items: ['HK1 2024-2025', 'HK2 2024-2025']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Dropdown cho khoa (ví dụ)
        Container(
          width: 200,
          child: DropdownButtonFormField<String>(
            value: 'all',
            items: ['Tất cả các khoa', 'Khoa CNTT', 'Khoa Cơ khí']
                .map((e) => DropdownMenuItem(value: e == 'Tất cả các khoa' ? 'all' : e, child: Text(e)))
                .toList(),
            onChanged: (value) {},
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download),
          label: const Text('Xuất báo cáo tổng hợp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D6EBA),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF0D6EBA),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF0D6EBA),
        indicatorWeight: 3.0,
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Giờ giảng'),
          Tab(text: 'Chuyên cần'),
        ],
      ),
    );
  }

  // --- CÁC TAB ---

  Widget _buildOverviewTab(OverviewReport data) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 2.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildKpiCard('Tổng giờ giảng', data.kpiCards.totalHours, Colors.blue, Icons.timer_outlined),
                  _buildKpiCard('Số giảng viên', data.kpiCards.lecturerCount, Colors.green, Icons.person_outline),
                  _buildKpiCard('Tỷ lệ hoàn thành', data.kpiCards.completionRate, Colors.purple, Icons.trending_up, isPercentage: true),
                  _buildKpiCard('Buổi nghỉ/dạy bù', data.kpiCards.leaveMakeupSessions, Colors.orange, Icons.calendar_today_outlined),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          // Bar Chart and Pie Chart
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 1000;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildMonthlyHoursChart(data.monthlyHoursChart)),
                    const SizedBox(width: 30),
                    Expanded(flex: 2, child: _buildAttendancePieChart(data.attendancePieChart)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildMonthlyHoursChart(data.monthlyHoursChart),
                  const SizedBox(height: 30),
                  _buildAttendancePieChart(data.attendancePieChart),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          _buildDepartmentProgress(data.departmentProgress),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTeachingHoursTab(TeachingHoursReport data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopLecturersTable(data.topLecturers),
          const SizedBox(height: 30),
          // Có thể thêm biểu đồ Xu hướng giờ giảng ở đây
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(AttendanceReport data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAttendanceSummaryCards(data.summary),
          const SizedBox(height: 30),
          _buildAttendanceByDepartment(data.byDepartment)
        ],
      ),
    );
  }

  // --- WIDGETS TÁI SỬ DỤNG CHO CÁC TAB ---

  // --- Tab Tổng Quan ---

  Widget _buildKpiCard(String title, KpiCardData data, Color color, IconData icon, {bool isPercentage = false}) {
    final formatter = NumberFormat("#,##0.##");
    final valueString = isPercentage ? "${formatter.format(data.value)}%" : formatter.format(data.value);
    final isPositive = data.change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                const SizedBox(height: 8),
                Text(valueString, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(child: Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? Colors.green : Colors.red, size: 16)),
                      TextSpan(text: ' ${data.change}% so với kỳ trước', style: TextStyle(color: isPositive ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyHoursChart(List<MonthlyHour> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giờ giảng theo tháng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: item.planned.toDouble(), color: Colors.blue, width: 15, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: item.actual.toDouble(), color: Colors.green, width: 15, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: item.makeup.toDouble(), color: Colors.orange, width: 15, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(data[value.toInt()].month, style: const TextStyle(fontSize: 12)))),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 90),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancePieChart(AttendancePieChart data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chuyên cần sinh viên', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(value: data.present, color: Colors.teal, title: '${data.present}%', radius: 80),
                  PieChartSectionData(value: data.excusedAbsence, color: Colors.orange, title: '${data.excusedAbsence}%', radius: 80),
                  PieChartSectionData(value: data.unexcusedAbsence, color: Colors.red, title: '${data.unexcusedAbsence}%', radius: 80),
                ],
                sectionsSpace: 4,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildLegendItem('Có mặt', Colors.teal), const SizedBox(width: 16),
            _buildLegendItem('Vắng có phép', Colors.orange), const SizedBox(width: 16),
            _buildLegendItem('Vắng không phép', Colors.red),
          ]),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(children: [Container(width: 16, height: 16, color: color), const SizedBox(width: 8), Text(text)]);
  }

  Widget _buildDepartmentProgress(List<DepartmentProgress> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tiến độ giảng dạy theo khoa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...data.map((item) => _buildProgressRow(item)).toList(),
        ],
      ),
    );
  }

  // --- 👇 BẮT ĐẦU PHẦN SỬA ĐỔI ---
  Widget _buildProgressRow(DepartmentProgress item) {
    // Kiểm tra nếu item.total là 0, thì mặc định tỷ lệ là 0.
    // Điều này sẽ ngăn chặn lỗi chia cho 0.
    final double percentage = (item.total == 0) ? 0.0 : (item.actual / item.total);

    final List<Color> colors = [Colors.green, Colors.blue, Colors.orange];
    final color = colors[item.name.hashCode % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentage, // Sử dụng giá trị 'percentage' đã được kiểm tra
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
                '  ${item.actual}/${item.total} giờ (${(percentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: Colors.grey.shade700)
            ),
          ),
        ],
      ),
    );
  }
  // --- 👆 KẾT THÚC PHẦN SỬA ĐỔI ---

  // --- Tab Giờ Giảng ---
  Widget _buildTopLecturersTable(List<TopLecturer> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Giảng viên có giờ giảng cao nhất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
              columns: const [
                DataColumn(label: Text('STT')),
                DataColumn(label: Text('Giảng viên')),
                DataColumn(label: Text('Khoa')),
                DataColumn(label: Text('Số lớp')),
                DataColumn(label: Text('Tổng giờ')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: data.map((lecturer) => DataRow(cells: [
                DataCell(Text(lecturer.rank.toString())),
                DataCell(Text(lecturer.name)),
                DataCell(Text(lecturer.department)),
                DataCell(Text(lecturer.classCount.toString())),
                DataCell(Text("${lecturer.totalHours}h", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                    child: Text(lecturer.status, style: const TextStyle(color: Colors.green)))),
              ])).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab Chuyên Cần ---
  Widget _buildAttendanceSummaryCards(AttendanceSummary data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAttendanceCard('Tổng số buổi có mặt', data.present, Colors.green),
            _buildAttendanceCard('Vắng có phép', data.excusedAbsence, Colors.orange),
            _buildAttendanceCard('Vắng không phép', data.unexcusedAbsence, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceCard(String title, AttendanceSummaryCard data, Color color) {
    final formatter = NumberFormat("#,##0");
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(formatter.format(data.value), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          Text('${data.percentage}% tổng số buổi', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceByDepartment(List<AttendanceByDepartment> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chuyên cần theo khoa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...data.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                SizedBox(width: 150, child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Có mặt: ${item.present}%'),
                      Text('CP: ${item.excused}%', style: TextStyle(color: Colors.orange.shade700)),
                      Text('KP: ${item.unexcused}%', style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                )
              ],
            ),
          )).toList()
        ],
      ),
    );
  }

}