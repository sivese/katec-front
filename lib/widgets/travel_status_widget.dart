import 'package:flutter/material.dart';
import 'empty_button_widget.dart';

enum TravelStatus { noTravel, ongoingTravel, upcomingTravel }

// TODO: Data Fetching 전환 시 수정할 부분
// 1. TravelStatus enum을 실제 데이터 모델로 교체
// 2. TravelStatusWidget의 status 파라미터를 실제 Travel 데이터로 변경
// 3. 각 _build 메서드에서 하드코딩된 데이터를 동적 데이터로 교체
class TravelStatusWidget extends StatelessWidget {
  final TravelStatus status;

  const TravelStatusWidget({super.key, required this.status});

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
          const EmptyButtonWidget(
            text: 'Create New Travel',
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildOngoingTravelWidget() {
    // TODO: Data Fetching 전환 시 수정할 부분
    // 1. ongoingTravel 데이터를 파라미터로 받도록 변경
    // 2. 하드코딩된 "Tokyo Trip"을 동적 데이터로 교체
    // 3. 다음 일정 정보를 실제 스케줄 데이터로 교체
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
          const Text(
            'Tokyo Trip',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Next Schedule',
            style: TextStyle(color: Color(0xFF888888), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visit Tokyo Tower',
                        style: TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Today 2:00 PM',
                        style: TextStyle(
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
    // TODO: Data Fetching 전환 시 수정할 부분
    // 1. upcomingTravel 데이터를 파라미터로 받도록 변경
    // 2. 하드코딩된 "Paris Trip"을 동적 데이터로 교체
    // 3. D-Day 계산을 실제 출발일로부터 계산하도록 변경
    // 4. 출발일을 동적 데이터로 교체
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
          const Text(
            'Paris Trip',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'D-15',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Departure: Jan 15, 2024',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
