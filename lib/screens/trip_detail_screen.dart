import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../models/recommendation.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../widgets/activity_filter_widget.dart';
import 'trip_management_screen.dart'; // Added import for TripManagementScreen
import 'add_schedule_screen.dart';
import 'edit_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ActivityType? _selectedActivityType;
  bool _isDeleting = false;

  Trip? _tripDetail; // 상세 trip 정보
  List<Activity> _activities = []; // 상세 activities(숙박 등)
  bool _isLoading = true;
  String? _error;

  // Recommendation 관련 변수들
  bool _showRecommendations = false;
  final List<Recommendation> _recommendations = [
    const Recommendation(
      id: 'rec_001',
      title: 'Stanley Park',
      description: '도심 속 거대한 공원, 산책/자전거 코스 훌륭',
      location: 'Vancouver, BC',
      category: 'Nature',
      estimatedDuration: 90,
      recommendedStartTime: TimeOfDay(hour: 9, minute: 0),
      recommendedEndTime: TimeOfDay(hour: 18, minute: 0),
      localTip: 'Seawall 코스 반시계 방향으로 돌면 뷰가 좋아요',
      imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba',
      address: '2000 W Georgia St, Vancouver, BC V6G 2P9, Canada',
    ),
    const Recommendation(
      id: 'rec_002',
      title: 'Granville Island Public Market',
      description: '현지 먹거리와 아티스트 숍 구경',
      location: 'Vancouver, BC',
      category: 'Dining',
      estimatedDuration: 60,
      recommendedStartTime: TimeOfDay(hour: 11, minute: 0),
      recommendedEndTime: TimeOfDay(hour: 15, minute: 0),
      localTip: '피크타임 전 11시 이전이 한산',
      imageUrl: 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9',
      address: '1669 Johnston St, Vancouver, BC V6H 3R9, Canada',
    ),
    const Recommendation(
      id: 'rec_003',
      title: 'Vancouver Art Gallery',
      description: '현대미술 전시가 다양',
      location: 'Vancouver, BC',
      category: 'Culture',
      estimatedDuration: 75,
      recommendedStartTime: TimeOfDay(hour: 13, minute: 0),
      recommendedEndTime: TimeOfDay(hour: 16, minute: 0),
      localTip: '비 오는 날 코스로 좋아요',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      address: '750 Hornby St, Vancouver, BC V6Z 2H7, Canada',
    ),
    const Recommendation(
      id: 'rec_004',
      title: 'Gastown',
      description: '스팀클락, 빈티지 상점, 카페',
      location: 'Vancouver, BC',
      category: 'Shopping',
      estimatedDuration: 50,
      recommendedStartTime: TimeOfDay(hour: 17, minute: 0),
      recommendedEndTime: TimeOfDay(hour: 21, minute: 0),
      localTip: '스팀클락 정각 증기쇼 타이밍 맞추기',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c',
      address: 'Water St, Vancouver, BC V6B 1B8, Canada',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTripDetails();
  }

  Future<void> _fetchTripDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception('Authentication token not found');
      final apiService = ApiService();
      final response = await apiService.getTripDetails(token, widget.trip.id);
      // trip 정보 파싱
      final tripJson = response['trip'] as Map<String, dynamic>;
      final trip = Trip(
        id: tripJson['tripId'] ?? '',
        title: tripJson['tripName'] ?? '',
        destination: tripJson['destination'] ?? '',
        startDate: DateTime.parse(tripJson['startDate']),
        endDate: DateTime.parse(tripJson['endDate']),
        status: TripStatus.planning, // 필요시 매핑
        description: '',
      );
      // 모든 subTrips를 type 필드로 구분하여 파싱
      final activities = <Activity>[];
      final subTripsData = response['subTrips'];
      List<dynamic> allSubTrips = [];
      if (subTripsData is Map<String, dynamic>) {
        final accommodations =
            (subTripsData['accommodations'] as List<dynamic>? ?? []);
        final transportations =
            (subTripsData['transportations'] as List<dynamic>? ?? []);
        final others = (subTripsData['otherSubTrips'] as List<dynamic>? ?? []);
        final dinings = (subTripsData['dinings'] as List<dynamic>? ?? []);
        allSubTrips = [
          ...accommodations,
          ...transportations,
          ...others,
          ...dinings,
        ];
      } else if (subTripsData is List<dynamic>) {
        allSubTrips = subTripsData;
      }

      for (final subTrip in allSubTrips) {
        final typeRaw = subTrip['type'];
        String type = typeRaw is String ? typeRaw : '';
        switch (type) {
          case 'Accommodation':
            activities.add(
              Activity(
                id: subTrip['subTripId'] ?? subTrip['_id'] ?? '',
                title: subTrip['accommodationName'] ?? subTrip['title'] ?? '',
                description: subTrip['description'] ?? '',
                type: ActivityType.accommodation,
                status: ActivityStatus.planned,
                startTime: DateTime.parse(
                  subTrip['checkInDate'] ?? subTrip['date'],
                ),
                endTime: DateTime.parse(
                  subTrip['checkOutDate'] ?? subTrip['date'],
                ),
                location: subTrip['location'] ?? '',
                bookingReference: subTrip['bookingReference'],
                notes: null,
              ),
            );
            break;
          case 'Transportation':
            activities.add(
              Activity(
                id: subTrip['subTripId'] ?? subTrip['_id'] ?? '',
                title:
                    '${subTrip['transportationType'] ?? ''} - ${subTrip['departure'] ?? ''} to ${subTrip['destination'] ?? ''}',
                description: subTrip['bookingReference'] ?? '',
                type: ActivityType.transportation,
                status: ActivityStatus.planned,
                startTime: DateTime.parse(
                  subTrip['departureDateTime'] ?? subTrip['date'],
                ),
                endTime: DateTime.parse(
                  subTrip['arrivalDateTime'] ?? subTrip['date'],
                ),
                location:
                    '${subTrip['departure'] ?? ''} → ${subTrip['destination'] ?? ''}',
                bookingReference: subTrip['bookingReference'],
                notes: null,
                transportationType: subTrip['transportationType'] is int
                    ? subTrip['transportationType']
                    : int.tryParse(
                        subTrip['transportationType']?.toString() ?? '',
                      ),
                departure: subTrip['departure'] ?? '',
                destination: subTrip['destination'] ?? '',
              ),
            );
            break;
          case 'Dining':
            final date = DateTime.parse(subTrip['date']);
            final startTimeParts = (subTrip['startTime'] as String).split(':');
            final endTimeParts = (subTrip['endTime'] as String).split(':');
            final startDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(startTimeParts[0]),
              int.parse(startTimeParts[1]),
            );
            final endDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(endTimeParts[0]),
              int.parse(endTimeParts[1]),
            );
            activities.add(
              Activity(
                id: subTrip['subTripId'] ?? subTrip['_id'] ?? '',
                title: subTrip['title'] ?? '',
                description: subTrip['description'] ?? '',
                type: ActivityType.dining,
                status: ActivityStatus.planned,
                startTime: startDateTime,
                endTime: endDateTime,
                location: subTrip['location'] ?? '',
                bookingReference: null,
                notes: null,
              ),
            );
            break;
          case 'Other':
            final date = DateTime.parse(subTrip['date']);
            final startTimeParts = (subTrip['startTime'] as String).split(':');
            final endTimeParts = (subTrip['endTime'] as String).split(':');
            final startDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(startTimeParts[0]),
              int.parse(startTimeParts[1]),
            );
            final endDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              int.parse(endTimeParts[0]),
              int.parse(endTimeParts[1]),
            );
            activities.add(
              Activity(
                id: subTrip['subTripId'] ?? subTrip['_id'] ?? '',
                title: subTrip['title'] ?? '',
                description: subTrip['description'] ?? '',
                type: ActivityType.activity,
                status: ActivityStatus.planned,
                startTime: startDateTime,
                endTime: endDateTime,
                location: subTrip['location'] ?? '',
                bookingReference: null,
                notes: null,
              ),
            );
            break;
          default:
            // Unknown type, 무시
            break;
        }
      }
      setState(() {
        _tripDetail = trip;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 현재 날짜 기준으로 여행 상태를 계산
  TripStatus _calculateCurrentStatus() {
    final trip = _tripDetail ?? widget.trip;
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
  Color _getCurrentStatusColor() {
    final status = _calculateCurrentStatus();
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
  String _getCurrentStatusText() {
    final status = _calculateCurrentStatus();
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

  Future<void> _deleteTrip() async {
    // 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Delete Trip',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${widget.trip.title}"? This action cannot be undone.',
            style: const TextStyle(color: Color(0xFFCCCCCC)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // 토큰 가져오기
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // API 서비스를 통한 Trip 삭제
      final apiService = ApiService();
      await apiService.deleteTrip(token, widget.trip.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Trip 삭제 성공 결과를 전달하여 이전 화면에서 새로고침 트리거
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete trip: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
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
          onPressed: () {
            // Trip Management 화면으로 돌아가기
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const TripManagementScreen(),
              ),
            );
          },
        ),
        title: Text(
          _tripDetail?.title ?? widget.trip.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              // 여행 수정 화면으로 이동
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      EditTripScreen(trip: _tripDetail ?? widget.trip),
                ),
              );
              // 수정이 성공했으면 여행 정보 새로고침
              if (result == true) {
                _fetchTripDetails();
              }
            },
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.delete, color: Colors.red),
            onPressed: _isDeleting ? null : _deleteTrip,
            tooltip: 'Delete Trip',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Schedule'),
            Tab(text: 'Recommendation'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildScheduleTab(),
                _buildRecommendationTab(),
              ],
            ),
      floatingActionButton: _calculateCurrentStatus() == TripStatus.completed
          ? null // 완료된 여행에서는 FAB 숨김
          : FloatingActionButton(
              onPressed: () async {
                // 숙박 Activity 추가 화면으로 이동 후 복귀 시 새로고침
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddScheduleScreen(trip: _tripDetail ?? widget.trip),
                  ),
                );
                if (result == true) {
                  _fetchTripDetails();
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildOverviewTab() {
    final trip = _tripDetail ?? widget.trip;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 여행 기본 정보 카드 (기존 trip -> trip)
          Card(
            color: const Color(0xFF2A2A2A),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _getCurrentStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          trip.destination,
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
                          color: _getCurrentStatusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCurrentStatusText(),
                          style: TextStyle(
                            color: _getCurrentStatusColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (trip.description != null) ...[
                    Text(
                      trip.description!,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'Start Date',
                          _formatDate(trip.startDate),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'End Date',
                          _formatDate(trip.endDate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.access_time,
                          'Duration',
                          '${trip.durationInDays} days',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activity Summary
          const Text(
            'Activity Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivitySummary(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final activities = _activities;
    if (activities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No activities registered yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 필터링된 활동 목록
    final filteredActivities = _selectedActivityType != null
        ? activities
              .where((activity) => activity.type == _selectedActivityType)
              .toList()
        : activities;

    if (filteredActivities.isEmpty) {
      return Column(
        children: [
          // 필터 위젯
          Container(
            margin: const EdgeInsets.only(top: 20),
            child: _buildActivityFilter(),
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No activities in selected category',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // 날짜별로 활동 그룹화
    final activitiesByDate = <DateTime, List<Activity>>{};
    for (final activity in filteredActivities) {
      final date = DateTime(
        activity.startTime.year,
        activity.startTime.month,
        activity.startTime.day,
      );
      activitiesByDate.putIfAbsent(date, () => []).add(activity);
    }

    final sortedDates = activitiesByDate.keys.toList()..sort();

    return Column(
      children: [
        // 필터 위젯
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: _buildActivityFilter(),
        ),
        // 활동 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20.0),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dayActivities = activitiesByDate[date]!;
              dayActivities.sort((a, b) => a.startTime.compareTo(b.startTime));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...dayActivities.map(
                    (activity) => _buildActivityCard(activity),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationTab() {
    if (!_showRecommendations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Get AI Recommendations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover personalized activities for your trip',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showRecommendations = true;
                });
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Get Recommendations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 추천 리스트 헤더
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'AI Recommendations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showRecommendations = false;
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.blue),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),

        // 추천 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              return _buildRecommendationCard(rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Recommendation rec) {
    final minutesText = rec.estimatedDuration >= 60
        ? '${rec.estimatedDuration ~/ 60}h ${rec.estimatedDuration % 60}m'
        : '${rec.estimatedDuration}m';

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 썸네일 이미지
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: rec.imageUrl != null
                  ? Image.network(
                      rec.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 48,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목과 카테고리
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rec.category,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 위치
                Row(
                  children: [
                    const Icon(Icons.place, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rec.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 설명
                Text(
                  rec.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),

                const SizedBox(height: 12),

                // 추가 정보 행
                Row(
                  children: [
                    Expanded(
                      child: _buildRecommendationInfo(
                        Icons.schedule,
                        'Duration: $minutesText',
                      ),
                    ),
                    Expanded(
                      child: _buildRecommendationInfo(
                        Icons.wb_sunny_outlined,
                        'Best: ${rec.recommendedStartTime != null && rec.recommendedEndTime != null ? '${rec.recommendedStartTime!.format(context)} - ${rec.recommendedEndTime!.format(context)}' : 'N/A'}',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 로컬 팁
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_outlined,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.localTip ?? 'No local tips available',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Add to Schedule 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _addToSchedule(rec);
                    },
                    icon: const Icon(
                      Icons.add_to_queue,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Add to Schedule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    final activities = _activities;
    final activityCounts = <ActivityType, int>{};

    for (final activity in activities) {
      activityCounts[activity.type] = (activityCounts[activity.type] ?? 0) + 1;
    }

    return Column(
      children: activityCounts.entries.map((entry) {
        final type = entry.key;
        final count = entry.value;
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(type.icon, color: type.color, size: 20),
            ),
            title: Text(
              type.displayName,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '$count',
              style: TextStyle(color: type.color, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityCard(Activity activity) {
    if (activity.type == ActivityType.accommodation) {
      // 숙박 전용 카드 (아코디언)
      final nights = activity.endTime.difference(activity.startTime).inDays;
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hotel, color: Colors.blue, size: 20),
          ),
          title: Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_formatDate(activity.startTime)} ~ ${_formatDate(activity.endTime)} ($nights nights)',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Accommodation',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity.bookingReference != null &&
                      activity.bookingReference!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Booking: ${activity.bookingReference}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (activity.location.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Location: ${activity.location}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (activity.description.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          activity.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Check-in: ${_formatDate(activity.startTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Check-out: ${_formatDate(activity.endTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (_calculateCurrentStatus() != TripStatus.completed)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 수정 모드로 이동
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddScheduleScreen(
                                trip: _tripDetail ?? widget.trip,
                                accommodation: activity,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchTripDetails();
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _deleteAccommodation(activity);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } else if (activity.type == ActivityType.transportation) {
      // 교통 전용 카드 (아코디언)
      final duration = activity.endTime.difference(activity.startTime);
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.green,
              size: 20,
            ),
          ),
          title: Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_formatDate(activity.startTime)} ${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Transport',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity.bookingReference != null &&
                      activity.bookingReference!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Booking: ${activity.bookingReference}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (activity.location.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Route: ${activity.location}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Departure: ${_formatDate(activity.startTime)} ${_formatTime(activity.startTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Arrival: ${_formatDate(activity.endTime)} ${_formatTime(activity.endTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (_calculateCurrentStatus() != TripStatus.completed)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 수정 모드로 이동
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddScheduleScreen(
                                trip: _tripDetail ?? widget.trip,
                                transportation: activity,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchTripDetails();
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 삭제 확인 다이얼로그
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF2A2A2A),
                                title: const Text(
                                  'Delete Transportation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
                                  style: const TextStyle(
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldDelete != true) return;
                          try {
                            final token = await TokenService.getToken();
                            if (token == null) {
                              throw Exception('Authentication token not found');
                            }
                            final apiService = ApiService();
                            await apiService.deleteTransportation(
                              token,
                              activity.id,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Transportation deleted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchTripDetails();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete transportation:  ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    if (activity.type == ActivityType.activity) {
      // 기타(Other) 전용 카드 (아코디언)
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event, color: Colors.orange, size: 20),
          ),
          title: Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_formatDate(activity.startTime)} ${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Other',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activity.location.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Location: ${activity.location}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  if (activity.description.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          activity.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Start: ${_formatDate(activity.startTime)} ${_formatTime(activity.startTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'End: ${_formatDate(activity.endTime)} ${_formatTime(activity.endTime)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (_calculateCurrentStatus() != TripStatus.completed)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 수정 모드로 이동
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddScheduleScreen(
                                trip: _tripDetail ?? widget.trip,
                                other: activity,
                              ),
                            ),
                          );
                          if (result == true) {
                            _fetchTripDetails();
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // 삭제 확인 다이얼로그
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF2A2A2A),
                                title: const Text(
                                  'Delete Other Schedule',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${activity.title}"? This action cannot be undone.',
                                  style: const TextStyle(
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldDelete != true) return;
                          try {
                            final token = await TokenService.getToken();
                            if (token == null) {
                              throw Exception('Authentication token not found');
                            }
                            final apiService = ApiService();
                            await apiService.deleteOtherSchedule(
                              token,
                              activity.id,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Other schedule deleted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _fetchTripDetails();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete other schedule: ${e.toString()}',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    if (activity.type == ActivityType.dining) {
      // 식당(Dining) 전용 카드 (아코디언)
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.purple, size: 20),
          ),
          title: Text(
            activity.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${_formatDate(activity.startTime)} ${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}',
            style: const TextStyle(
              color: Colors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Dining',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activity.location.isNotEmpty)
                    _buildInfoItem(
                      Icons.location_on,
                      'Location',
                      activity.location,
                    ),
                  if (activity.description.isNotEmpty)
                    _buildInfoItem(
                      Icons.description,
                      'Description',
                      activity.description,
                    ),
                  _buildInfoItem(
                    Icons.access_time,
                    'Duration',
                    activity.durationText,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // 수정 모드로 이동
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AddScheduleScreen(
                                  trip: _tripDetail ?? widget.trip,
                                  dining: activity,
                                ),
                              ),
                            );
                            if (result == true) {
                              _fetchTripDetails();
                            }
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Dining'),
                                content: Text(
                                  'Are you sure you want to delete "${activity.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (shouldDelete != true) return;
                            try {
                              final token = await TokenService.getToken();
                              if (token == null) {
                                throw Exception(
                                  'Authentication token not found',
                                );
                              }
                              final apiService = ApiService();
                              await apiService.deleteDiningSchedule(
                                token,
                                activity.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Dining schedule deleted successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchTripDetails();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to delete dining schedule: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 기타 활동(기존 방식)
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: activity.type.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(activity.type.icon, color: activity.type.color, size: 20),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.location,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              '${_formatTime(activity.startTime)} - ${_formatTime(activity.endTime)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: activity.status.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            activity.status.displayName,
            style: TextStyle(
              color: activity.status.color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          // TODO: Navigate to activity detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${activity.title} details coming soon.'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActivityFilter() {
    return ActivityFilterWidget(
      selectedType: _selectedActivityType,
      onTypeChanged: (type) {
        setState(() {
          _selectedActivityType = type;
        });
      },
    );
  }

  // 숙박 옵션 다이얼로그 표시
  void _showAccommodationOptions(Activity accommodation) {
    // 완료된 여행에서는 옵션 다이얼로그를 표시하지 않음
    if (_calculateCurrentStatus() == TripStatus.completed) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              accommodation.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                // 수정 모드로 이동
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddScheduleScreen(
                      trip: _tripDetail ?? widget.trip,
                      accommodation: accommodation,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchTripDetails();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteAccommodation(accommodation);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 추천을 일정에 추가하는 기능
  void _addToSchedule(Recommendation recommendation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Add to Schedule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add "${recommendation.title}" to your schedule?',
                style: const TextStyle(color: Color(0xFFCCCCCC)),
              ),
              const SizedBox(height: 16),
              Text(
                'Location: ${recommendation.address ?? recommendation.location}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'Duration: ${recommendation.estimatedDuration >= 60 ? '${recommendation.estimatedDuration ~/ 60}h ${recommendation.estimatedDuration % 60}m' : '${recommendation.estimatedDuration}m'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToAddSchedule(recommendation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // AddScheduleScreen으로 이동하여 추천 데이터 전달
  void _navigateToAddSchedule(Recommendation recommendation) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddScheduleScreen(
          trip: _tripDetail ?? widget.trip,
          recommendation: recommendation,
        ),
      ),
    );

    // 일정 추가가 성공했으면 데이터 새로고침
    if (result == true) {
      _fetchTripDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule added successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // 추천 데이터가 폼에 자동으로 채워졌음을 알리는 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recommendation data has been pre-filled in the form!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 숙박 삭제 기능
  Future<void> _deleteAccommodation(Activity accommodation) async {
    // 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Delete Accommodation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${accommodation.title}"? This action cannot be undone.',
            style: const TextStyle(color: Color(0xFFCCCCCC)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      // 토큰 가져오기
      final token = await TokenService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // API 서비스를 통한 숙박 삭제
      final apiService = ApiService();
      await apiService.deleteAccommodation(token, accommodation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accommodation deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // 숙박 목록 새로고침
        _fetchTripDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete accommodation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
