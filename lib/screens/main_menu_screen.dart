import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../widgets/section_title_widget.dart';
import '../widgets/travel_status_widget.dart';
import '../widgets/empty_button_widget.dart';
import 'trip_management_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 포커스를 받을 때마다 프로필 갱신 (초기로드도 포함)
    _refreshUserProfile();
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshUserProfile,
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
            // TODO: Data Fetching 전환 시 수정할 부분
            // 1. TravelStatusWidget을 StatefulWidget으로 변경하거나
            // 2. Provider/Bloc/GetX 등을 사용하여 상태 관리
            // 3. 실제 Travel 데이터를 가져와서 적절한 상태로 설정
            // 4. 로딩 상태 처리 추가
            // 5. 에러 상태 처리 추가

            // Travel status widget - 현재는 여행 없음 상태로 설정
            const TravelStatusWidget(status: TravelStatus.noTravel),

            // 다른 상태들을 테스트하려면 아래 comment 변경:
            // const TravelStatusWidget(status: TravelStatus.ongoingTravel),
            // const TravelStatusWidget(status: TravelStatus.upcomingTravel),
            const SizedBox(height: 20),
            EmptyButtonWidget(
              text: 'Manage My Trip',
              width: double.infinity,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TripManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
