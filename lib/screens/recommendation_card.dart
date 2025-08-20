import 'package:flutter/material.dart';
import '../models/recommendation.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercury Card Recommendation',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.black54),
      home: const RecommendationPage(),
    );
  }
}

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final String _sort = '추천순';
  final Set<String> _selectedCats = {};
  final List<Recommendation> _all = [
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

  List<String> get _categories =>
      _all.map((e) => e.category).toSet().toList()..sort();

  List<Recommendation> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final cats = _selectedCats;
    final list = _all.where((r) {
      final hit =
          r.title.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      final catOk = cats.isEmpty || cats.contains(r.category);
      return hit && catOk;
    }).toList();

    switch (_sort) {
      case '시간 적은 순':
        list.sort((a, b) => a.estimatedDuration.compareTo(b.estimatedDuration));
        break;
      case '시간 많은 순':
        list.sort((a, b) => b.estimatedDuration.compareTo(a.estimatedDuration));
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
      appBar: AppBar(title: const Text('Recommendation'), actions: []),
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

  const RecommendationCard({super.key, required this.rec, this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final minutesText = rec.estimatedDuration >= 60
        ? '${rec.estimatedDuration ~/ 60}시간 ${rec.estimatedDuration % 60}분'
        : '${rec.estimatedDuration}분';

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
              child: Stack(
                children: [
                  rec.imageUrl != null
                      ? Ink.image(
                          image: NetworkImage(rec.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 48,
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Chip(
                      label: Text(rec.category),
                      backgroundColor: Colors.black.withOpacity(0.5),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
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
            _InfoRow(
              icon: Icons.wb_sunny_outlined,
              text:
                  '베스트 타임: ${rec.recommendedStartTime != null && rec.recommendedEndTime != null ? '${rec.recommendedStartTime!.format(context)} - ${rec.recommendedEndTime!.format(context)}' : 'N/A'}',
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rec.description,
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
                      rec.localTip ?? 'No local tips available',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 8),
          Text('검색 결과가 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '검색어를 바꾸거나 필터를 해제해 보세요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
