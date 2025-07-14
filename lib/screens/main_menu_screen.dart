import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../models/trip.dart';
import '../widgets/section_title_widget.dart';
import '../widgets/travel_status_widget.dart';
import '../widgets/empty_button_widget.dart';
import 'trip_management_screen.dart';
import 'create_trip_screen.dart';
import 'login_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final String token;

  const MainMenuScreen({super.key, required this.token});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  String _userName = 'Loading...';
  bool _isLoading = true;
  String? _error;
  bool _hasLoadedInitialProfile = false;
  List<Trip> _trips = [];
  Trip? _currentTrip;

  Trip _fromApiJson(Map<String, dynamic> json) {
    String tripId;
    if (json['tripId'] != null) {
      tripId = json['tripId'].toString();
    } else if (json['id'] is Map) {
      final idMap = json['id'] as Map;
      tripId = idMap['timestamp']?.toString() ?? '';
    } else {
      tripId = json['id']?.toString() ?? '';
    }

    return Trip(
      id: tripId,
      title: json['tripName'] ?? '',
      destination: json['destination'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: TripStatus.planning,
      description: '',
      activities: [],
    );
  }

  TravelStatus _determineTravelStatus(List<Trip> trips) {
    if (trips.isEmpty) {
      return TravelStatus.noTravel;
    }

    final now = DateTime.now();

    // 현재 진행 중인 여행이 있는지 확인
    final ongoingTrip = trips.where((trip) {
      return trip.startDate.isBefore(now) && trip.endDate.isAfter(now);
    }).toList();

    if (ongoingTrip.isNotEmpty) {
      _currentTrip = ongoingTrip.first;
      return TravelStatus.ongoingTravel;
    }

    // 다가오는 여행이 있는지 확인
    final upcomingTrip = trips.where((trip) {
      return trip.startDate.isAfter(now);
    }).toList();

    if (upcomingTrip.isNotEmpty) {
      _currentTrip = upcomingTrip.first;
      return TravelStatus.upcomingTravel;
    }

    return TravelStatus.noTravel;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTrips();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 포커스를 받을 때마다 프로필과 Trip 데이터 갱신
    _refreshUserProfile();
    _loadTrips();
  }

  Future<void> _loadUserProfile() async {
    try {
      final apiService = ApiService();
      final profile = await apiService.getUserProfile(widget.token);

      if (mounted) {
        final userName = profile['name'] ?? 'Unknown';
        setState(() {
          _userName = userName;
          _isLoading = false;
          _hasLoadedInitialProfile = true;
        });

        // 사용자 이름 저장
        await TokenService.saveUserName(userName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _hasLoadedInitialProfile = true;
        });
      }
    }
  }

  Future<void> _loadTrips() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getTripList(widget.token);

      final tripsJson = response['trips'] as List<dynamic>? ?? [];
      final trips = tripsJson
          .map((e) => _fromApiJson(e as Map<String, dynamic>))
          .toList();

      // 시작일 기준으로 정렬 (가장 가까운 여행이 먼저 오도록)
      trips.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (mounted) {
        setState(() {
          _trips = trips;
        });
      }
    } catch (e) {
      // Trip 로딩 실패는 에러로 표시하지 않고 빈 배열로 처리
      if (mounted) {
        setState(() {
          _trips = [];
        });
      }
    }
  }

  Future<void> _refreshUserProfile() async {
    try {
      final apiService = ApiService();
      final profile = await apiService.getUserProfile(widget.token);

      // 웹의 경우 console.log(profile) 출력
      print(profile);

      if (mounted) {
        final userName = profile['name'] ?? 'Unknown';
        setState(() {
          _userName = userName;
          _error = null; // 에러 상태 초기화
        });

        // 사용자 이름 저장
        await TokenService.saveUserName(userName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    // 로그아웃 확인 다이얼로그 표시
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Color(0xFFCCCCCC)),
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
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true && mounted) {
      // 토큰 및 사용자 정보 삭제
      await TokenService.clearToken();

      // 로그인 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // 모든 이전 화면 제거
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final travelStatus = _determineTravelStatus(_trips);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _refreshUserProfile();
              _loadTrips();
            },
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            if (_isLoading)
              const SectionTitleWidget(title: 'Loading...')
            else if (_error != null)
              SectionTitleWidget(title: 'Error: $_error')
            else
              SectionTitleWidget(title: 'Hello $_userName'),
            const SizedBox(height: 20),

            // Travel status widget - 실제 Trip 데이터 기반으로 상태 결정
            TravelStatusWidget(
              status: travelStatus,
              trip: _currentTrip,
              onCreateTrip: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateTripScreen(),
                  ),
                );

                // Trip 생성이 성공했으면 새로고침
                if (result == true) {
                  _loadTrips();
                }
              },
            ),
            const SizedBox(height: 20),
            EmptyButtonWidget(
              text: 'Manage My Trip',
              width: double.infinity,
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TripManagementScreen(),
                  ),
                );

                // Trip Management에서 변경사항이 있었으면 새로고침
                if (result == true) {
                  _loadTrips();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
