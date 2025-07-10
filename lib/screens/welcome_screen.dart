import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'login_screen.dart';
import 'main_menu_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  bool _isCheckingServer = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 각 텍스트에 대한 슬라이드 애니메이션 생성
    _slideAnimations = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(1.0, 0.0), // 오른쪽에서 시작
        end: Offset.zero, // 원래 위치로
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15, // 각 텍스트마다 0.15초씩 지연
            (index + 1) * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    // 각 텍스트에 대한 페이드 애니메이션 생성
    _fadeAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            (index + 1) * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    // 애니메이션 시작
    _animationController.forward();

    // 애니메이션 완료 후 서버 상태 확인
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCheckingServer) {
        _checkServerHealth();
      }
    });
  }

  // 서버 상태 확인 및 로그인 상태 체크
  Future<void> _checkServerHealth() async {
    if (_isCheckingServer) return;

    setState(() {
      _isCheckingServer = true;
    });

    try {
      final apiService = ApiService();
      final healthResponse = await apiService.healthCheck();

      // 서버가 정상인지 확인
      if (healthResponse['status'] == 'Healthy') {
        // 로그인 상태 확인
        final isLoggedIn = await TokenService.isLoggedIn();
        final token = await TokenService.getToken();

        if (mounted) {
          if (isLoggedIn && token != null) {
            // 토큰이 있으면 프로필 요청으로 유효성 확인
            try {
              final apiService = ApiService();
              await apiService.getUserProfile(token);

              // 프로필 요청 성공 - 메인 메뉴로 이동
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainMenuScreen(token: token),
                ),
              );
            } catch (e) {
              // 토큰이 유효하지 않음 - 저장된 토큰 삭제 후 로그인 화면으로 이동
              await TokenService.clearToken();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          } else {
            // 로그인되지 않은 경우 로그인 화면으로 이동
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else {
        throw Exception('Server is not healthy: ${healthResponse['status']}');
      }
    } catch (e) {
      if (mounted) {
        // 서버 연결 실패 시 에러 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text(
                'Connection Error',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Unable to connect to server.\n\nError: ${e.toString()}',
                style: const TextStyle(color: Color(0xFFCCCCCC)),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkServerHealth(); // 재시도
                  },
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingServer = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: _slideAnimations[0],
                  child: FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: const Text(
                      'All',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _slideAnimations[1],
                  child: FadeTransition(
                    opacity: _fadeAnimations[1],
                    child: const Text(
                      'Your',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _slideAnimations[2],
                  child: FadeTransition(
                    opacity: _fadeAnimations[2],
                    child: const Text(
                      'Trips',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _slideAnimations[3],
                  child: FadeTransition(
                    opacity: _fadeAnimations[3],
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: _slideAnimations[4],
                  child: FadeTransition(
                    opacity: _fadeAnimations[4],
                    child: const Text(
                      'Here',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 서버 상태 확인 중 로딩 인디케이터
          if (_isCheckingServer)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Checking server connection...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
