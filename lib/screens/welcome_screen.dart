import 'package:flutter/material.dart';
import 'login_screen.dart';

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

    // TODO: Data Fetching 전환 시 수정할 부분
    // 1. 자동 로그인 체크 로직 추가
    // 2. 토큰 유효성 검증
    // 3. 로그인 상태에 따라 다른 화면으로 이동
    // 4. 스플래시 화면 시간 조정

    // 3초 후 로그인 화면으로 자동 이동 (애니메이션 시간 고려)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
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
      body: Padding(
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
    );
  }
}
