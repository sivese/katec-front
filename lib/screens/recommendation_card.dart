import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercury Card Recommendation',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.black54,
      ),
      home: const RecommendationPage(),
    );
  }
}

class Recommendation {
  final String title;
  final String location;
  final String why;
  final String bestTime;
  final int minutes; // Estimated time in minutes
  final String localTip;
  final String imageUrl;
  final String category;

  const Recommendation({
    required this.title,
    required this.location,
    required this.why,
    required this.bestTime,
    required this.minutes,
    required this.localTip,
    required this.imageUrl,
    required this.category,
  });
}

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _sort = '추천순';
  final Set<String> _selectedCats = {};
  final List<Recommendation> _all = [
    const Recommendation(
      title: '스탠리 파크',
      location: 'Vancouver, BC',
      why: '도심 속 거대한 공원, 산책/자전거 코스 훌륭',
      bestTime: '오전~해질녘',
      minutes: 90,
      localTip: 'Seawall 코스 반시계 방향으로 돌면 뷰가 좋아요',
      imageUrl: 'https://images.unsplash.com/photo-1519681393784-d120267933ba',
      category: '자연',
    ),
    const Recommendation(
      title: '그랜빌 아일랜드 퍼블릭 마켓',
      location: 'Vancouver, BC',
      why: '현지 먹거리와 아티스트 숍 구경',
      bestTime: '점심 전후',
      minutes: 60,
      localTip: '피크타임 전 11시 이전이 한산',
      imageUrl: 'https://images.unsplash.com/photo-1498654896293-37aacf113fd9',
      category: '맛집',
    ),
    const Recommendation(
      title: '밴쿠버 미술관',
      location: 'Vancouver, BC',
      why: '현대미술 전시가 다양',
      bestTime: '오후',
      minutes: 75,
      localTip: '비 오는 날 코스로 좋아요',
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      category: '전시',
    ),
    const Recommendation(
      title: '개스타운',
      location: 'Vancouver, BC',
      why: '스팀클락, 빈티지 상점, 카페',
      bestTime: '해질녘~저녁',
      minutes: 50,
      localTip: '스팀클락 정각 증기쇼 타이밍 맞추기',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c',
      category: '산책',
    ),
  ];

  List<String> get _categories =>
      _all.map((e) => e.category).toSet().toList()..sort();

  List<Recommendation> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final cats = _selectedCats;
    final list = _all.where((r) {
      final hit = r.title.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.why.toLowerCase().contains(q);
      final catOk = cats.isEmpty || cats.contains(r.category);
      return hit && catOk;
    }).toList();

    switch (_sort) {
      case '시간 적은 순':
        list.sort((a, b) => a.minutes.compareTo(b.minutes));
        break;
      case '시간 많은 순':
        list.sort((a, b) => b.minutes.compareTo(a.minutes));
        break;
      case '이름순':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case '추천순':
      default:
      // 데모용: 기본순서 유지
        break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation'),
        actions: [
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터칩
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: cats.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  final selected = _selectedCats.isEmpty;
                  return FilterChip(
                    selected: selected,
                    label: const Text('전체'),
                    onSelected: (_) => setState(() => _selectedCats.clear()),
                  );
                }
                final cat = cats[i - 1];
                final selected = _selectedCats.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedCats.add(cat);
                    } else {
                      _selectedCats.remove(cat);
                    }
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 결과 리스트
          Expanded(
            child: _filtered.isEmpty
                ? const _EmptyState()
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final r = _filtered[i];
                return RecommendationCard(
                  rec: r,
                  onBookmark: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('북마크: ${r.title}')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  final VoidCallback? onBookmark;

  const RecommendationCard({
    super.key,
    required this.rec,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final minutesText =
    rec.minutes >= 60 ? '${rec.minutes ~/ 60}시간 ${rec.minutes % 60}분' : '${rec.minutes}분';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Ink.image(
                image: NetworkImage(rec.imageUrl),
                fit: BoxFit.cover,
                child: Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(8),
                  child: Chip(
                    label: Text(rec.category),
                    backgroundColor: Colors.black.withOpacity(0.5),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rec.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: onBookmark,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: '북마크',
                  ),
                ],
              ),
            ),
            _InfoRow(icon: Icons.place, text: rec.location),
            _InfoRow(icon: Icons.schedule, text: '소요시간: $minutesText'),
            _InfoRow(icon: Icons.wb_sunny_outlined, text: '베스트 타임: ${rec.bestTime}'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rec.why,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rec.localTip,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.search_off, size: 48),
        const SizedBox(height: 8),
        Text(
          '검색 결과가 없어요',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          '검색어를 바꾸거나 필터를 해제해 보세요',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}