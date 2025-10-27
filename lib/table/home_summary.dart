import 'dart:convert';

HomeSummary homeSummaryFromJson(String str) => HomeSummary.fromJson(json.decode(str));

class HomeSummary {
  final Summary summary;
  final List<TodaySchedule> todaySchedules;

  HomeSummary({
    required this.summary,
    required this.todaySchedules,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
    summary: Summary.fromJson(json["summary"]),
    todaySchedules: List<TodaySchedule>.from(json["today_schedules"].map((x) => TodaySchedule.fromJson(x))),
  );
}

class Summary {
  final int todayLessons;
  final int weekLessons;
  final double completionPercent;

  Summary({
    required this.todayLessons,
    required this.weekLessons,
    required this.completionPercent,
  });

  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    todayLessons: (json["today_lessons"] as num).toInt(),
    weekLessons: (json["week_lessons"] as num).toInt(),
    completionPercent: (json["completion_percent"] as num).toDouble(),
  );
}

class TodaySchedule {
  final int id;
  final String timeRange;
  final String lessons;
  final String title;
  final String courseCode;
  final String location;
  final String status;

  TodaySchedule({
    required this.id,
    required this.timeRange,
    required this.lessons,
    required this.title,
    required this.courseCode,
    required this.location,
    required this.status,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> json) => TodaySchedule(
    id: json["id"],
    timeRange: json["time_range"],
    lessons: json["lessons"],
    title: json["title"],
    courseCode: json["course_code"],
    location: json["location"],
    status: json["status"],
  );
}