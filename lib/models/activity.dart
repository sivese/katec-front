import 'package:flutter/material.dart';

enum ActivityType {
  accommodation, // 숙박
  transportation, // 교통
  activity, // 기타 활동
  dining, // 식당
}

enum ActivityStatus {
  planned, // 계획됨
  confirmed, // 확정됨
  completed, // 완료됨
  cancelled, // 취소됨
}

class Activity {
  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final ActivityStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? bookingReference;
  final String? notes;
  final List<String> attachments; // 이미지, 문서 등 첨부파일
  final int? transportationType; // 교통수단 인덱스(0~5)
  final String? departure; // 출발지
  final String? destination; // 도착지

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.bookingReference,
    this.notes,
    this.attachments = const [],
    this.transportationType,
    this.departure,
    this.destination,
  });

  // 활동 기간 계산 (시간 단위)
  Duration get duration {
    return endTime.difference(startTime);
  }

  // 활동 기간을 문자열로 반환
  String get durationText {
    final duration = this.duration;
    if (duration.inHours < 1) {
      return '${duration.inMinutes}min';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} h ${duration.inMinutes % 60} min';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '$days day $hours hours';
    }
  }
}

extension ActivityTypeExtension on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.accommodation:
        return 'Accommodation';
      case ActivityType.transportation:
        return 'Transportation';
      case ActivityType.activity:
        return 'Activity';
      case ActivityType.dining:
        return 'Dining';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.accommodation:
        return Icons.hotel;
      case ActivityType.transportation:
        return Icons.directions_car;
      case ActivityType.activity:
        return Icons.event;
      case ActivityType.dining:
        return Icons.restaurant;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.accommodation:
        return Colors.blue;
      case ActivityType.transportation:
        return Colors.green;
      case ActivityType.activity:
        return Colors.orange;
      case ActivityType.dining:
        return Colors.purple;
    }
  }
}

extension ActivityStatusExtension on ActivityStatus {
  String get displayName {
    switch (this) {
      case ActivityStatus.planned:
        return 'Planned';
      case ActivityStatus.confirmed:
        return 'Confirmed';
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ActivityStatus.planned:
        return Colors.blue;
      case ActivityStatus.confirmed:
        return Colors.green;
      case ActivityStatus.completed:
        return Colors.grey;
      case ActivityStatus.cancelled:
        return Colors.red;
    }
  }
}
