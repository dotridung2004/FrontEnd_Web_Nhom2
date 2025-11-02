// lib/models/report_data.dart

class ReportData {
  final OverviewReport overview;
  final TeachingHoursReport teachingHours;
  final AttendanceReport attendance;

  ReportData({
    required this.overview,
    required this.teachingHours,
    required this.attendance,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      overview: OverviewReport.fromJson(json['overview']),
      teachingHours: TeachingHoursReport.fromJson(json['teaching_hours']),
      attendance: AttendanceReport.fromJson(json['attendance']),
    );
  }
}

// --- Overview Tab ---
class OverviewReport {
  final KpiCards kpiCards;
  final List<MonthlyHour> monthlyHoursChart;
  final AttendancePieChart attendancePieChart;
  final List<DepartmentProgress> departmentProgress;

  OverviewReport({
    required this.kpiCards,
    required this.monthlyHoursChart,
    required this.attendancePieChart,
    required this.departmentProgress,
  });

  factory OverviewReport.fromJson(Map<String, dynamic> json) {
    return OverviewReport(
      kpiCards: KpiCards.fromJson(json['kpi_cards']),
      monthlyHoursChart: (json['monthly_hours_chart'] as List)
          .map((item) => MonthlyHour.fromJson(item))
          .toList(),
      attendancePieChart:
      AttendancePieChart.fromJson(json['attendance_pie_chart']),
      departmentProgress: (json['department_progress'] as List)
          .map((item) => DepartmentProgress.fromJson(item))
          .toList(),
    );
  }
}

class KpiCards {
  final KpiCardData totalHours;
  final KpiCardData lecturerCount;
  final KpiCardData completionRate;
  final KpiCardData leaveMakeupSessions;

  KpiCards({
    required this.totalHours,
    required this.lecturerCount,
    required this.completionRate,
    required this.leaveMakeupSessions,
  });

  factory KpiCards.fromJson(Map<String, dynamic> json) {
    return KpiCards(
      totalHours: KpiCardData.fromJson(json['total_hours']),
      lecturerCount: KpiCardData.fromJson(json['lecturer_count']),
      completionRate: KpiCardData.fromJson(json['completion_rate']),
      leaveMakeupSessions: KpiCardData.fromJson(json['leave_makeup_sessions']),
    );
  }
}

class KpiCardData {
  final num value;
  final num change;
  KpiCardData({required this.value, required this.change});
  factory KpiCardData.fromJson(Map<String, dynamic> json) {
    return KpiCardData(value: json['value'], change: json['change']);
  }
}

class MonthlyHour {
  final String month;
  final num planned;
  final num actual;
  final num makeup;
  MonthlyHour({required this.month, required this.planned, required this.actual, required this.makeup});
  factory MonthlyHour.fromJson(Map<String, dynamic> json) {
    return MonthlyHour(month: json['month'], planned: json['planned'], actual: json['actual'], makeup: json['makeup']);
  }
}

class AttendancePieChart {
  final double present;
  final double excusedAbsence;
  final double unexcusedAbsence;
  AttendancePieChart({required this.present, required this.excusedAbsence, required this.unexcusedAbsence});
  factory AttendancePieChart.fromJson(Map<String, dynamic> json) {
    return AttendancePieChart(
      present: (json['present'] as num).toDouble(),
      excusedAbsence: (json['excused_absence'] as num).toDouble(),
      unexcusedAbsence: (json['unexcused_absence'] as num).toDouble(),
    );
  }
}

class DepartmentProgress {
  final String name;
  final int actual;
  final int total;
  DepartmentProgress({required this.name, required this.actual, required this.total});
  factory DepartmentProgress.fromJson(Map<String, dynamic> json) {
    return DepartmentProgress(name: json['name'], actual: json['actual'], total: json['total']);
  }
}


// --- Teaching Hours Tab ---
class TeachingHoursReport {
  final List<TopLecturer> topLecturers;
  // Thêm các model khác nếu cần
  TeachingHoursReport({required this.topLecturers});

  factory TeachingHoursReport.fromJson(Map<String, dynamic> json) {
    return TeachingHoursReport(
      topLecturers: (json['top_lecturers'] as List)
          .map((item) => TopLecturer.fromJson(item))
          .toList(),
    );
  }
}

class TopLecturer {
  final int rank;
  final String name;
  final String department;
  final int classCount;
  final int totalHours;
  final String status;

  TopLecturer({
    required this.rank,
    required this.name,
    required this.department,
    required this.classCount,
    required this.totalHours,
    required this.status,
  });

  factory TopLecturer.fromJson(Map<String, dynamic> json) {
    return TopLecturer(
      rank: json['rank'],
      name: json['name'],
      department: json['department'],
      classCount: json['class_count'],
      totalHours: json['total_hours'],
      status: json['status'],
    );
  }
}


// --- Attendance Tab ---
class AttendanceReport {
  final AttendanceSummary summary;
  final List<AttendanceByDepartment> byDepartment;

  AttendanceReport({required this.summary, required this.byDepartment});

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      summary: AttendanceSummary.fromJson(json['summary']),
      byDepartment: (json['by_department'] as List)
          .map((item) => AttendanceByDepartment.fromJson(item))
          .toList(),
    );
  }
}

class AttendanceSummary {
  final AttendanceSummaryCard present;
  final AttendanceSummaryCard excusedAbsence;
  final AttendanceSummaryCard unexcusedAbsence;

  AttendanceSummary({required this.present, required this.excusedAbsence, required this.unexcusedAbsence});

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      present: AttendanceSummaryCard.fromJson(json['present']),
      excusedAbsence: AttendanceSummaryCard.fromJson(json['excused_absence']),
      unexcusedAbsence: AttendanceSummaryCard.fromJson(json['unexcused_absence']),
    );
  }
}
class AttendanceSummaryCard {
  final int value;
  final double percentage;
  AttendanceSummaryCard({required this.value, required this.percentage});
  factory AttendanceSummaryCard.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryCard(value: json['value'], percentage: (json['percentage'] as num).toDouble());
  }
}

class AttendanceByDepartment {
  final String name;
  final int present;
  final int excused;
  final int unexcused;
  AttendanceByDepartment({required this.name, required this.present, required this.excused, required this.unexcused});
  factory AttendanceByDepartment.fromJson(Map<String, dynamic> json) {
    return AttendanceByDepartment(name: json['name'], present: json['present'], excused: json['excused'], unexcused: json['unexcused']);
  }
}