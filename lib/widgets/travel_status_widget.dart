import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'empty_button_widget.dart';

enum TravelStatus { noTravel, ongoingTravel, upcomingTravel }

class TravelStatusWidget extends StatelessWidget {
  final TravelStatus status;
  final Trip? trip; // 실제 Trip 데이터 추가
  final VoidCallback? onCreateTrip;

  const TravelStatusWidget({
    super.key,
    required this.status,
    this.trip,
    this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case TravelStatus.noTravel:
        return _buildNoTravelWidget();
      case TravelStatus.ongoingTravel:
        return _buildOngoingTravelWidget();
      case TravelStatus.upcomingTravel:
        return _buildUpcomingTravelWidget();
    }
  }

  Widget _buildNoTravelWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.flight_takeoff, color: Color(0xFF888888), size: 48),
          const SizedBox(height: 16),
          const Text(
            'No Travel Plans',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new travel plan',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          const SizedBox(height: 20),
          EmptyButtonWidget(
            text: 'Create New Travel',
            width: double.infinity,
            onPressed: onCreateTrip,
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTravelWidget() {
    if (trip == null) {
      return _buildNoTravelWidget();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Ongoing Travel',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            trip!.title,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trip!.destination,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip!.startDate.day}/${trip!.startDate.month} - ${trip!.endDate.day}/${trip!.endDate.month}',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Currently traveling',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTravelWidget() {
    if (trip == null) {
      return _buildNoTravelWidget();
    }

    final now = DateTime.now();
    final daysUntilTrip = trip!.startDate.difference(now).inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9800), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: Color(0xFFFF9800), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Upcoming Travel',
                style: TextStyle(
                  color: Color(0xFFFF9800),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            trip!.title,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trip!.destination,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'D-$daysUntilTrip',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Departure: ${trip!.startDate.day}/${trip!.startDate.month}/${trip!.startDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
