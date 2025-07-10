import 'package:flutter/material.dart';

enum ActivityType {
  accommodation, // 숙박
  transportation, // 교통
  sightseeing, // 관광
  dining, // 식사
  shopping, // 쇼핑
  entertainment, // 엔터테인먼트
  other, // 기타
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
  });

  // 활동 기간 계산 (시간 단위)
  Duration get duration {
    return endTime.difference(startTime);
  }

  // 활동 기간을 문자열로 반환
  String get durationText {
    final duration = this.duration;
    if (duration.inHours < 1) {
      return '${duration.inMinutes}분';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}시간 ${duration.inMinutes % 60}분';
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '$days일 $hours시간';
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
      case ActivityType.sightseeing:
        return 'Sightseeing';
      case ActivityType.dining:
        return 'Dining';
      case ActivityType.shopping:
        return 'Shopping';
      case ActivityType.entertainment:
        return 'Entertainment';
      case ActivityType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.accommodation:
        return Icons.hotel;
      case ActivityType.transportation:
        return Icons.directions_car;
      case ActivityType.sightseeing:
        return Icons.photo_camera;
      case ActivityType.dining:
        return Icons.restaurant;
      case ActivityType.shopping:
        return Icons.shopping_bag;
      case ActivityType.entertainment:
        return Icons.movie;
      case ActivityType.other:
        return Icons.more_horiz;
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.accommodation:
        return Colors.blue;
      case ActivityType.transportation:
        return Colors.green;
      case ActivityType.sightseeing:
        return Colors.orange;
      case ActivityType.dining:
        return Colors.red;
      case ActivityType.shopping:
        return Colors.purple;
      case ActivityType.entertainment:
        return Colors.pink;
      case ActivityType.other:
        return Colors.grey;
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
