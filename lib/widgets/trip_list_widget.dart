import 'package:flutter/material.dart';
import '../models/trip.dart';

class TripListWidget extends StatelessWidget {
  final List<Trip> trips;
  final Function(Trip)? onTripTap;

  const TripListWidget({super.key, required this.trips, this.onTripTap});

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 64, color: Color(0xFF888888)),
            SizedBox(height: 16),
            Text(
              'No trips yet',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start planning your next adventure!',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(trip: trip, onTap: () => onTripTap?.call(trip));
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;

  const _TripCard({required this.trip, this.onTap});

  // 현재 날짜 기준으로 여행 상태를 계산
  TripStatus _calculateCurrentStatus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final endDate = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    if (endDate.isBefore(today)) {
      return TripStatus.completed;
    } else if (startDate.isAfter(today)) {
      return TripStatus.planning;
    } else {
      return TripStatus.ongoing;
    }
  }

  // 상태에 따른 색상 반환
  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return const Color(0xFF4CAF50); // 초록색
      case TripStatus.ongoing:
        return const Color(0xFF2196F3); // 파란색
      case TripStatus.completed:
        return const Color(0xFF9E9E9E); // 회색
      default:
        return const Color(0xFF4CAF50);
    }
  }

  // 상태에 따른 표시 텍스트 반환
  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planned';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      default:
        return 'Planned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _calculateCurrentStatus();
    final statusColor = _getStatusColor(currentStatus);
    final statusText = _getStatusText(currentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trip.destination,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF888888),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
