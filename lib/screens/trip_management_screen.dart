import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../widgets/trip_list_widget.dart';
import '../widgets/empty_button_widget.dart';
import 'trip_detail_screen.dart';
import 'create_trip_screen.dart';

class TripManagementScreen extends StatefulWidget {
  const TripManagementScreen({super.key});

  @override
  State<TripManagementScreen> createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen>
    with SingleTickerProviderStateMixin {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;
  bool _hasChanges = false; // 변경사항 추적
  late TabController _tabController;
  List<Trip> _activeTrips = [];
  List<Trip> _completedTrips = [];

  Trip _fromApiJson(Map<String, dynamic> json) {
    // tripId 필드 확인을 위한 디버깅
    print('Processing trip: ${json['tripName']}');
    print('Available fields: ${json.keys.toList()}');
    print('tripId field: ${json['tripId']}');
    print('id field: ${json['id']}');

    String tripId;
    if (json['tripId'] != null) {
      tripId = json['tripId'].toString();
      print('Using tripId: $tripId');
    } else if (json['id'] is Map) {
      final idMap = json['id'] as Map;
      // fallback: timestamp를 사용
      tripId = idMap['timestamp']?.toString() ?? '';
      print('Using timestamp as fallback: $tripId');
    } else {
      tripId = json['id']?.toString() ?? '';
      print('Using direct id: $tripId');
    }

    return Trip(
      id: tripId,
      title: json['tripName'] ?? '',
      destination: json['destination'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: TripStatus.planning, // 상태값은 필요시 추가 매핑
      description: '',
      activities: [],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 포커스를 받을 때마다 Trip 데이터 새로고침
    _loadTrips();
  }

  void _categorizeTrips() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _activeTrips = _trips.where((trip) {
      final endDate = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
      );
      return endDate.isAfter(today) || endDate.isAtSameMomentAs(today);
    }).toList();

    _completedTrips = _trips.where((trip) {
      final endDate = DateTime(
        trip.endDate.year,
        trip.endDate.month,
        trip.endDate.day,
      );
      return endDate.isBefore(today);
    }).toList();

    // 각 카테고리 내에서 시작일 기준으로 정렬
    _activeTrips.sort((a, b) => a.startDate.compareTo(b.startDate));
    _completedTrips.sort(
      (a, b) => b.endDate.compareTo(a.endDate),
    ); // 완료된 여행은 최근 완료된 순으로
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 토큰 가져오기
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // API 서비스를 통한 Trip 목록 조회
      final apiService = ApiService();
      final response = await apiService.getTripList(token);

      final tripsJson = response['trips'] as List<dynamic>? ?? [];
      final trips = tripsJson
          .map((e) => _fromApiJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _trips = trips;
        _isLoading = false;
      });

      // 여행을 카테고리별로 분류
      _categorizeTrips();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trips: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _createNewTrip() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateTripScreen()));

    // Trip 생성이 성공했으면 새로고침
    if (result == true) {
      _hasChanges = true; // 변경사항 표시
      _loadTrips();
    }
  }

  void _onTripTap(Trip trip) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
    );

    // Trip 삭제가 성공했으면 새로고침
    if (result == true) {
      _hasChanges = true; // 변경사항 표시
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 변경사항이 있었으면 결과를 전달
        Navigator.of(context).pop(_hasChanges);
        return false; // 기본 뒤로가기 동작 방지
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // 변경사항이 있었으면 결과를 전달
              Navigator.of(context).pop(_hasChanges);
            },
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Active/Planned (${_activeTrips.length})'),
              Tab(text: 'Completed (${_completedTrips.length})'),
            ],
          ),
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

              // 탭바 뷰
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 진행중/예정인 여행 탭
                    _buildActiveTripsTab(),
                    // 완료된 여행 탭
                    _buildCompletedTripsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active/Planned Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildTripListContent(_activeTrips)),
      ],
    );
  }

  Widget _buildCompletedTripsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildTripListContent(_completedTrips)),
      ],
    );
  }

  Widget _buildTripListContent(List<Trip> trips) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadTrips, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (trips.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, color: Color(0xFF888888), size: 48),
            SizedBox(height: 16),
            Text(
              'No trips found',
              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first trip to get started',
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return TripListWidget(trips: trips, onTripTap: _onTripTap);
  }
}
