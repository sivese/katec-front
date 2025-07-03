import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../widgets/trip_list_widget.dart';
import '../widgets/empty_button_widget.dart';

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
        ),
        Trip(
          id: '2',
          title: 'Busan Trip',
          destination: 'Busan',
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          endDate: DateTime.now().subtract(const Duration(days: 2)),
          status: TripStatus.completed,
        ),
        Trip(
          id: '3',
          title: 'Tokyo Trip',
          destination: 'Tokyo, Japan',
          startDate: DateTime.now().add(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 35)),
          status: TripStatus.planning,
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
    // TODO: Trip 상세 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${trip.title} details are coming soon.'),
        backgroundColor: Colors.blue,
      ),
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
