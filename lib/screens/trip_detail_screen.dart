import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../models/activity.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../widgets/activity_filter_widget.dart';
import 'trip_management_screen.dart'; // Added import for TripManagementScreen
import 'add_accommodation_screen.dart'; // Added import for AddAccommodationScreen

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
      // 숙박 리스트 파싱 (accommodations)
      final accommodations =
          (response['subTrips']?['accommodations'] as List<dynamic>? ?? []);
      final activities = accommodations.map((a) {
        return Activity(
          id: a['subTripId'] ?? '',
          title: a['accommodationName'] ?? '',
          description: a['description'] ?? '',
          type: ActivityType.accommodation,
          status: ActivityStatus.planned, // 필요시 매핑
          startTime: DateTime.parse(a['checkInDate']),
          endTime: DateTime.parse(a['checkOutDate']),
          location: trip.destination,
          bookingReference: a['bookingReference'],
          notes: null,
        );
      }).toList();
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
            onPressed: () {
              // TODO: Navigate to trip edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trip edit feature coming soon.'),
                  backgroundColor: Colors.blue,
                ),
              );
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
            Tab(text: 'Notes'),
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
                _buildNotesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 숙박 Activity 추가 화면으로 이동 후 복귀 시 새로고침
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddAccommodationScreen(trip: _tripDetail ?? widget.trip),
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
                        color: trip.status.color,
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
                          color: trip.status.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          trip.status.displayName,
                          style: TextStyle(
                            color: trip.status.color,
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
                          '시작일',
                          _formatDate(trip.startDate),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          '종료일',
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

  Widget _buildNotesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Notes feature coming soon',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
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
      // 숙박 전용 카드
      final nights = activity.endTime.difference(activity.startTime).inDays;
      return Card(
        color: const Color(0xFF2A2A2A),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatDate(activity.startTime)} ~ ${_formatDate(activity.endTime)} (${nights}박)',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (activity.bookingReference != null &&
                  activity.bookingReference!.isNotEmpty)
                Text(
                  'Booking: ${activity.bookingReference}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              if (activity.description.isNotEmpty)
                Text(
                  activity.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '숙박',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
    return '${date.year}년 ${date.month}월 ${date.day}일';
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
}
