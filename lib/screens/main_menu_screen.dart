import 'package:flutter/material.dart';
import '../widgets/section_title_widget.dart';
import '../widgets/travel_status_widget.dart';
import '../widgets/empty_button_widget.dart';
import 'trip_management_screen.dart';

class MainMenuScreen extends StatelessWidget {
  final String userName;

  const MainMenuScreen({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            SectionTitleWidget(title: 'Hello $userName'),
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
