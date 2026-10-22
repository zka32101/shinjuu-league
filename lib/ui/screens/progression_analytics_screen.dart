import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/config/theme.dart';
import 'package:shinjuu_league/data/models/progression_stats.dart';
import 'package:shinjuu_league/services/auth_service.dart';
import 'package:shinjuu_league/viewmodels/progression_analytics_viewmodel.dart';

/// プレイヤーの通算進行状況（シーズン統計・Tier推移・ELO推移グラフ）を表示する画面。
///
/// `ProgressionAnalyticsViewModel`/`ProgressionAnalyticsService`は実装済み
/// だったが、`progressionAnalyticsServiceProvider`が常にUnimplementedErrorを
/// 投げるダミーのままで、かつこの画面自体がどこにも存在しなかった
/// （配線忘れではなく、配線先の画面が最初から無かった）。
/// `AchievementsScreen`と同じ`userIdOverride`テストシームパターンを踏襲。
class ProgressionAnalyticsScreen extends ConsumerStatefulWidget {
  const ProgressionAnalyticsScreen({super.key, this.userIdOverride});

  final String? userIdOverride;

  @override
  ConsumerState<ProgressionAnalyticsScreen> createState() =>
      _ProgressionAnalyticsScreenState();
}

class _ProgressionAnalyticsScreenState
    extends ConsumerState<ProgressionAnalyticsScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final userId = widget.userIdOverride ?? _resolveCurrentUserId();
    _userId = userId;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(progressionAnalyticsViewModelProvider(userId).notifier)
            .loadProgressionStats();
      });
    }
  }

  String? _resolveCurrentUserId() {
    try {
      return AuthService().currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('進行状況'), centerTitle: true),
      body: userId == null
          ? const Center(child: Text('ログインが必要です'))
          : _buildBody(userId),
    );
  }

  Widget _buildBody(String userId) {
    final viewModel = ref.read(progressionAnalyticsViewModelProvider(userId).notifier);
    final state = ref.watch(progressionAnalyticsViewModelProvider(userId));

    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.stats == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('エラー: ${state.error}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => viewModel.loadProgressionStats(),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    final stats = state.stats;
    if (stats == null || stats.allSeasons.isEmpty) {
      return const Center(child: Text('まだシーズンのプレイ記録がありません'));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadProgressionStats(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(viewModel: viewModel, stats: stats),
          const SizedBox(height: 16),
          _EloChartCard(chartData: viewModel.getEloChartData()),
          const SizedBox(height: 16),
          _TierPredictionCard(userId: userId),
          const SizedBox(height: 16),
          _SeasonHistoryCard(seasons: stats.allSeasons),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.viewModel, required this.stats});

  final ProgressionAnalyticsViewModel viewModel;
  final ProgressionStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  viewModel.getTrendEmoji(),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.getTrendDescription(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        stats.getRankChange(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _StatItem(label: '現在Tier', value: viewModel.getCurrentTier()),
                _StatItem(
                  label: '最高Tier',
                  value: viewModel.getHighestTierEver(),
                ),
                _StatItem(
                  label: '通算勝率',
                  value:
                      '${(viewModel.getCareerWinRate() * 100).toStringAsFixed(1)}%',
                ),
                _StatItem(
                  label: '通算試合数',
                  value: '${viewModel.getTotalGamesPlayed()}',
                ),
                _StatItem(
                  label: 'プレイシーズン数',
                  value: '${viewModel.getSeasonsPlayed()}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _EloChartCard extends StatelessWidget {
  const _EloChartCard({required this.chartData});

  final List<({DateTime date, double rating})> chartData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今シーズンのELO推移',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (chartData.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('データがありません')),
              )
            else
              SizedBox(
                height: 120,
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: _EloSparklinePainter(chartData),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// シンプルなスパークライン描画。グラフライブラリへの依存を増やさず、
/// ELO推移の上下動だけが一目でわかれば十分という割り切り。
class _EloSparklinePainter extends CustomPainter {
  _EloSparklinePainter(this.data);

  final List<({DateTime date, double rating})> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final ratings = data.map((d) => d.rating).toList();
    final minRating = ratings.reduce((a, b) => a < b ? a : b);
    final maxRating = ratings.reduce((a, b) => a > b ? a : b);
    final range = (maxRating - minRating).clamp(1.0, double.infinity);

    final paint = Paint()
      ..color = AppColors.accentBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length == 1 ? 0.0 : size.width * i / (data.length - 1);
      final normalized = (data[i].rating - minRating) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EloSparklinePainter oldDelegate) =>
      oldDelegate.data != data;
}

class _TierPredictionCard extends ConsumerWidget {
  const _TierPredictionCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionAsync = ref.watch(tierPredictionProvider(userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '次Tier予測',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            predictionAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('予測データを取得できませんでした'),
              data: (prediction) {
                if (prediction == null) {
                  return const Text('予測に十分なデータがありません');
                }
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${prediction.currentTier} → ${prediction.predictedTier}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '確信度 ${(prediction.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonHistoryCard extends StatelessWidget {
  const _SeasonHistoryCard({required this.seasons});

  final List<SeasonStats> seasons;

  @override
  Widget build(BuildContext context) {
    final reversed = seasons.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'シーズン履歴',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final season in reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  child: Text(
                    season.finalTier.substring(0, 1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(season.finalTier),
                subtitle: Text(
                  '${season.gamesWon}勝${season.gamesLost}敗 '
                  '(${(season.winRate * 100).toStringAsFixed(0)}%)',
                ),
                trailing: Text(
                  '最高 ${season.maxTierReached}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
