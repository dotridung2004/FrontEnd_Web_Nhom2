// lib/models/room_detail.dart
import 'schedule.dart'; // Bạn cần import model Schedule.dart của mình

class RoomDetail {
  final int id;
  final String name;
  final String building;
  final int floor;
  final int capacity;
  final String type;
  final String status;
  final String description;
  final List<Schedule> schedules; // Danh sách lịch học liên quan

  RoomDetail({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.status,
    required this.description,
    required this.schedules,
  });

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    // Giả định API trả về { id: ..., name: ..., schedules: [...] }
    final roomData = json;
    final scheduleData = json['schedules'] as List? ?? [];

    return RoomDetail(
      id: roomData['id'] ?? 0,
      name: roomData['name'] ?? 'N/A',
      building: roomData['building'] ?? 'N/A',
      floor: (roomData['floor'] as num?)?.toInt() ?? 0,
      capacity: (roomData['capacity'] as num?)?.toInt() ?? 0,
      type: roomData['room_type'] ?? 'N/A',
      status: roomData['status'] ?? 'N/A',
      description: roomData['description'] ?? '',
      schedules: scheduleData.map((item) => Schedule.fromJson(item)).toList(),
    );
  }
}