import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final TripStatus status;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
}

enum TripStatus {
  planning, // 계획 중
  upcoming, // 예정된 여행
  ongoing, // 진행 중
  completed, // 완료된 여행
  cancelled, // 취소된 여행
}

extension TripStatusExtension on TripStatus {
  String get displayName {
    switch (this) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.upcoming:
        return 'Upcoming';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case TripStatus.planning:
        return Colors.blue;
      case TripStatus.upcoming:
        return Colors.orange;
      case TripStatus.ongoing:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }
}
