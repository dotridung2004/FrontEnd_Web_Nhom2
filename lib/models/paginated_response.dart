// lib/models/paginated_response.dart

import 'app_user.dart';

class PaginatedUsersResponse {
  final List<AppUser> users;
  final int currentPage;
  final int lastPage;
  final int totalItems;
  final int? from;
  final int? to;

  PaginatedUsersResponse({
    required this.users,
    required this.currentPage,
    required this.lastPage,
    required this.totalItems,
    this.from,
    this.to,
  });

  factory PaginatedUsersResponse.fromJson(Map<String, dynamic> json) {
    var userList = json['data'] as List;
    List<AppUser> users = userList.map((i) => AppUser.fromJson(i)).toList();

    return PaginatedUsersResponse(
      users: users,
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      totalItems: json['total'],
      from: json['from'],
      to: json['to'],
    );
  }
}