import 'package:flutter/material.dart';

class Recommendation {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final int estimatedDuration; // in minutes
  final TimeOfDay? recommendedStartTime; // Recommended start time for visit
  final TimeOfDay? recommendedEndTime; // Recommended end time for visit
  final String? localTip;
  final String? address; // Detailed address instead of coordinates
  final String? website;
  final String? phoneNumber;
  final Map<String, dynamic>? additionalInfo; // for flexible additional data

  const Recommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.estimatedDuration,
    this.recommendedStartTime,
    this.recommendedEndTime,
    this.localTip,
    this.address,
    this.website,
    this.phoneNumber,
    this.additionalInfo,
  });

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'category': category,
      'estimatedDuration': estimatedDuration,
      'recommendedStartTime': recommendedStartTime != null
          ? '${recommendedStartTime!.hour.toString().padLeft(2, '0')}:${recommendedStartTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'recommendedEndTime': recommendedEndTime != null
          ? '${recommendedEndTime!.hour.toString().padLeft(2, '0')}:${recommendedEndTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'localTip': localTip,
      'address': address,
      'website': website,
      'phoneNumber': phoneNumber,
      'additionalInfo': additionalInfo,
    };
  }

  // JSON deserialization
  factory Recommendation.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      return null;
    }

    return Recommendation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      category: json['category'] ?? '',
      estimatedDuration: json['estimatedDuration'] ?? 0,
      recommendedStartTime: parseTime(json['recommendedStartTime']),
      recommendedEndTime: parseTime(json['recommendedEndTime']),
      localTip: json['localTip'],
      address: json['address'],
      website: json['website'],
      phoneNumber: json['phoneNumber'],
      additionalInfo: json['additionalInfo'],
    );
  }

  // Copy with method for creating modified instances
  Recommendation copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? category,
    int? estimatedDuration,
    TimeOfDay? recommendedStartTime,
    TimeOfDay? recommendedEndTime,
    String? localTip,
    String? address,
    String? website,
    String? phoneNumber,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Recommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      category: category ?? this.category,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      recommendedStartTime: recommendedStartTime ?? this.recommendedStartTime,
      recommendedEndTime: recommendedEndTime ?? this.recommendedEndTime,
      localTip: localTip ?? this.localTip,
      address: address ?? this.address,
      website: website ?? this.website,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
