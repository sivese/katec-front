import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../widgets/trip_list_widget.dart';
import '../widgets/empty_button_widget.dart';
import 'trip_detail_screen.dart';

class TripManagementScreen extends StatefulWidget {
  const TripManagementScreen({super.key});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen> {
  // TODO: Data Fetching 전환 시 수정할 부분
  // 1. 실제 API에서 Trip 데이터를 가져오도록 변경
  // 2. 상태 관리 라이브러리 사용 (Provider, Bloc, GetX 등)
  // 3. 로딩 상태 처리 추가
  // 4. 에러 상태 처리 추가
  // 5. 새로고침 기능 추가

  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    // 임시 데이터 - 실제로는 API 호출
    setState(() {
      _trips = [
        Trip(
          id: '1',
          title: 'Jeju Island Trip',
          destination: 'Jeju Island',
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 10)),
          status: TripStatus.upcoming,
          description:
              '3 nights 4 days trip to Jeju Island - hiking Hallasan and beach sightseeing',
          activities: [
            Activity(
              id: '1-1',
              title: 'Jeju Grand Hotel',
              description: '4-star hotel located in the center of Jeju City',
              type: ActivityType.accommodation,
              status: ActivityStatus.confirmed,
              startTime: DateTime.now().add(const Duration(days: 7)),
              endTime: DateTime.now().add(const Duration(days: 10)),
              location: '15 Gwandeok-ro, Jeju City',
              bookingReference: 'JEJU-HOTEL-001',
            ),
            Activity(
              id: '1-2',
              title: 'Jeju Airport → Hotel',
              description: 'Rental car transfer',
              type: ActivityType.transportation,
              status: ActivityStatus.confirmed,
              startTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
              endTime: DateTime.now().add(const Duration(days: 7, hours: 3)),
              location: 'Jeju Airport → Jeju City',
              bookingReference: 'CAR-RENTAL-001',
            ),
            Activity(
              id: '1-3',
              title: 'Hallasan Hiking',
              description:
                  'Hiking to the summit of Hallasan via Seongpanak trail',
              type: ActivityType.sightseeing,
              status: ActivityStatus.planned,
              startTime: DateTime.now().add(const Duration(days: 8, hours: 6)),
              endTime: DateTime.now().add(const Duration(days: 8, hours: 18)),
              location: 'Hallasan Seongpanak Trail',
            ),
            Activity(
              id: '1-4',
              title: 'Jeju Black Pork Restaurant',
              description: 'Famous Jeju black pork samgyeopsal',
              type: ActivityType.dining,
              status: ActivityStatus.planned,
              startTime: DateTime.now().add(const Duration(days: 8, hours: 19)),
              endTime: DateTime.now().add(const Duration(days: 8, hours: 21)),
              location: '20 Gwandeok-ro, Jeju City',
            ),
          ],
        ),
        Trip(
          id: '2',
          title: 'Busan Trip',
          destination: 'Busan',
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          endDate: DateTime.now().subtract(const Duration(days: 2)),
          status: TripStatus.completed,
          description:
              '2 nights 3 days trip to Busan - Haeundae Beach and Gamcheon Culture Village',
          activities: [
            Activity(
              id: '2-1',
              title: 'Haeundae Grand Hotel',
              description: 'Hotel with ocean view at Haeundae Beach',
              type: ActivityType.accommodation,
              status: ActivityStatus.completed,
              startTime: DateTime.now().subtract(const Duration(days: 5)),
              endTime: DateTime.now().subtract(const Duration(days: 2)),
              location: '264 Haeundaehaebyeon-ro, Haeundae-gu',
            ),
            Activity(
              id: '2-2',
              title: 'KTX to Busan',
              description: 'Seoul → Busan KTX',
              type: ActivityType.transportation,
              status: ActivityStatus.completed,
              startTime: DateTime.now().subtract(
                const Duration(days: 5, hours: 2),
              ),
              endTime: DateTime.now().subtract(
                const Duration(days: 5, hours: 4),
              ),
              location: 'Seoul Station → Busan Station',
            ),
            Activity(
              id: '2-3',
              title: 'Gamcheon Culture Village',
              description: 'Santorini of Busan - Gamcheon Culture Village tour',
              type: ActivityType.sightseeing,
              status: ActivityStatus.completed,
              startTime: DateTime.now().subtract(
                const Duration(days: 4, hours: 10),
              ),
              endTime: DateTime.now().subtract(
                const Duration(days: 4, hours: 16),
              ),
              location: 'Gamcheon-dong, Saha-gu',
            ),
          ],
        ),
        Trip(
          id: '3',
          title: 'Tokyo Trip',
          destination: 'Tokyo, Japan',
          startDate: DateTime.now().add(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 35)),
          status: TripStatus.planning,
          description:
              '5 nights 6 days trip to Tokyo - Shibuya, Harajuku, Akihabara',
          activities: [
            Activity(
              id: '3-1',
              title: 'Shibuya Hotel',
              description: 'Hotel near Shibuya Station',
              type: ActivityType.accommodation,
              status: ActivityStatus.planned,
              startTime: DateTime.now().add(const Duration(days: 30)),
              endTime: DateTime.now().add(const Duration(days: 35)),
              location: '1-1-1 Shibuya, Shibuya-ku',
            ),
            Activity(
              id: '3-2',
              title: 'Incheon Airport → Narita Airport',
              description: 'Korean Air KE705',
              type: ActivityType.transportation,
              status: ActivityStatus.planned,
              startTime: DateTime.now().add(const Duration(days: 30, hours: 8)),
              endTime: DateTime.now().add(const Duration(days: 30, hours: 11)),
              location: 'Incheon Airport → Narita Airport',
              bookingReference: 'KE705-2024-01-15',
            ),
          ],
        ),
      ];
    });
  }

  void _createNewTrip() {
    // TODO: 새 Trip 생성 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New trip creation feature is coming soon.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _onTripTap(Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Trips',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 새 여행 생성 버튼
            EmptyButtonWidget(
              text: 'Create New Trip',
              width: double.infinity,
              onPressed: _createNewTrip,
            ),
            const SizedBox(height: 24),

            // 여행 목록 제목
            const Text(
              'My Trip List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // 여행 목록
            Expanded(
              child: TripListWidget(trips: _trips, onTripTap: _onTripTap),
            ),
          ],
        ),
      ),
    );
  }
}
