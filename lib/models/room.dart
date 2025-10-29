import 'dart:convert';

class Room {
  final int id;
  final String name; // Số phòng (315-A2)
  final String building; // Tòa nhà (A2)
  final int floor; // Tầng (3)
  final int capacity; // Sức chứa (50)
  final String type; // Loại phòng (Lí thuyết)
  final String status; // Trạng thái (Hoạt động)

  Room({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      building: json['building'] ?? 'N/A',
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      type: json['type'] ?? 'N/A',
      status: json['status'] ?? 'N/A',
    );
  }
}