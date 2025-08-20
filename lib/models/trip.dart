import 'package:flutter/material.dart';
import 'activity.dart';

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final TripStatus status;
  final List<Activity> activities;
  final String? description;

  Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.activities = const [],
    this.description,
  });

  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  List<Activity> get accommodationActivities {
    return activities
        .where((activity) => activity.type == ActivityType.accommodation)
        .toList();
  }

  List<Activity> get transportationActivities {
    return activities
        .where((activity) => activity.type == ActivityType.transportation)
        .toList();
  }

  List<Activity> get activityActivities {
    return activities
        .where((activity) => activity.type == ActivityType.activity)
        .toList();
  }

  List<Activity> get diningActivities {
    return activities
        .where((activity) => activity.type == ActivityType.dining)
        .toList();
  }
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
