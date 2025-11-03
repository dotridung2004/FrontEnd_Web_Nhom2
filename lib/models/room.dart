// lib/models/room.dart
import 'dart:convert';

class Room {
  final int id;
  final String name;       // Mã phòng
  final String building;
  final int floor;
  final int capacity;
  final String type;
  final String status;
  final String description;

  Room({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.status,
    required this.description,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      building: json['building'] ?? 'N/A',
      floor: (json['floor'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      type: json['room_type'] ?? 'N/A', // Đọc từ room_type
      status: json['status'] ?? 'N/A',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'floor': floor,
      'capacity': capacity,
      'room_type': type, // Gửi về là room_type
      'status': status,
      'description': description,
    };
  }
}