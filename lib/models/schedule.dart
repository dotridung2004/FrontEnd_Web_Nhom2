import 'dart:convert';
import 'package:intl/intl.dart'; // Import for parsing date

// Helper remains the same
List<Schedule> scheduleListFromJson(String str) {
  final List<dynamic> data = json.decode(str);
  return List<Schedule>.from(data.map((x) => Schedule.fromJson(x)));
}

class Schedule {
  final int id;
  // Fields for displaying in the table
  final String teacherName;
  final String classCode;
  final String courseName;
  final String semester;
  final String roomName;

  // --- NEW: Fields needed for the Edit/View Form ---
  final int? classCourseAssignmentId;
  final int? roomId;
  final DateTime? date; // Store as DateTime for DatePicker
  final String session;

  Schedule({
    required this.id,
    required this.teacherName,
    required this.classCode,
    required this.courseName,
    required this.semester,
    required this.roomName,
    // --- NEW ---
    this.classCourseAssignmentId,
    this.roomId,
    this.date,
    required this.session,
  });

  /// Factory constructor to parse the FLATTENED JSON from the updated API
  factory Schedule.fromJson(Map<String, dynamic> json) {

    // Helper function to safely parse date string (Y-m-d)
    DateTime? parseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateFormat('yyyy-MM-dd').parse(dateString);
      } catch (e) {
        print("Error parsing date: $dateString - $e");
        return null;
      }
    }

    return Schedule(
      id: json['id'] ?? 0,

      // Read directly from the keys provided by ScheduleController::index()
      teacherName: json['teacherName'] ?? 'N/A',
      classCode:   json['classCode'] ?? 'N/A',
      courseName:  json['courseName'] ?? 'N/A',
      semester:    json['semester'] ?? 'N/A',
      roomName:    json['roomName'] ?? 'N/A',

      // --- NEW: Parse fields needed for the form ---
      classCourseAssignmentId: json['class_course_assignment_id'] as int?,
      roomId:                  json['room_id'] as int?,
      date:                    parseDate(json['date']), // Parse the date string
      session:                 json['session'] ?? 'N/A',
    );
  }
}