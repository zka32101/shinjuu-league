import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shinjuu_league/services/ranking_service.dart';

/// Season-over-season rating progression: a hand-painted line chart of
/// peak rating per season, plus a per-season detail list (tier reached,
/// rating range, win/loss). No charting package dependency, consistent
/// with this codebase's existing CustomPainter-based visuals (MechaGlyph,
/// isometric battlefield, etc.) rather than pulling in a chart library
/// for a single simple trend line.
class RankingHistoryWidget extends StatelessWidget {
  const RankingHistoryWidget({required this.entries, super.key});

  final List<SeasonHistoryEntry> entries;

  static const Map<String, Color> _tierColors = {
    'Bronze': Color(0xFFCD7F32),
    'Silver': Color(0xFFB0B0B8),
    'Gold': Color(0xFFFFC94D),
    'Platinum': Color(0xFF7FD8D8),
    'Diamond': Color(0xFF6FA8FF),
  };

  Color _colorForTier(String tier) => _tierColors[tier] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('まだシーズン参加履歴がありません')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _RatingTrendPainter(
                entries: entries,
                tierColor: _colorForTier,
                textColor:
                    Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        const Divider(height: 1),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            // Newest season first in the list, even though the chart above
            // reads left(oldest)-to-right(newest).
            final entry = entries[entries.length - 1 - index];
            final tierColor = _colorForTier(entry.peakTier);
            final totalGames = entry.seasonWins + entry.seasonLosses;
            final winRatePercent = totalGames == 0
                ? '—'
                : '${(entry.seasonWins / totalGames * 100).round()}%';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: tierColor,
                child: Text(
                  entry.peakTier.isNotEmpty ? entry.peakTier[0] : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(entry.seasonName),
              subtitle: Text(
                '${entry.startingRating} → ${entry.peakRating} (最終 ${entry.finalRating})'
                ' · ${entry.seasonWins}勝${entry.seasonLosses}敗 ($winRatePercent)',
              ),
              trailing: Text(
                entry.peakTier,
                style: TextStyle(color: tierColor, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RatingTrendPainter extends CustomPainter {
  _RatingTrendPainter({
    required this.entries,
    required this.tierColor,
    required this.textColor,
  });

  final List<SeasonHistoryEntry> entries;
  final Color Function(String tier) tierColor;
  final Color textColor;

  static const _leftPadding = 36.0;
  static const _bottomPadding = 20.0;
  static const _topPadding = 12.0;
  static const _rightPadding = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = (size.width - _leftPadding - _rightPadding).clamp(
      1.0,
      double.infinity,
    );
    final chartHeight = (size.height - _topPadding - _bottomPadding).clamp(
      1.0,
      double.infinity,
    );
    final chartLeft = _leftPadding;
    final chartTop = _topPadding;

    final ratings = entries.map((e) => e.peakRating).toList();
    final minRating = ratings.reduce((a, b) => a < b ? a : b).toDouble();
    final maxRating = ratings.reduce((a, b) => a > b ? a : b).toDouble();
    // A single season, or a season with no rating movement, would collapse
    // the y-axis to zero range; pad it so the line/dot still renders
    // mid-chart instead of dividing by zero.
    final range = (maxRating - minRating).abs() < 1
        ? 100.0
        : maxRating - minRating;
    final effectiveMin = (maxRating - minRating).abs() < 1
        ? minRating - 50
        : minRating;

    double xFor(int index) => entries.length == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + chartWidth * index / (entries.length - 1);
    double yFor(int rating) =>
        chartTop + chartHeight - (rating - effectiveMin) / range * chartHeight;

    // Axis line
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(chartLeft, chartTop + chartHeight),
      Offset(chartLeft + chartWidth, chartTop + chartHeight),
      axisPaint,
    );

    // Trend line connecting each season's peak rating
    final linePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final point = Offset(xFor(i), yFor(entries[i].peakRating));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Per-season point, colored by tier reached, plus its season label
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final point = Offset(xFor(i), yFor(entry.peakRating));
      canvas.drawCircle(point, 5, Paint()..color = tierColor(entry.peakTier));
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: DateFormat.MMM().format(entry.startedAt ?? DateTime.now()),
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(point.dx - labelPainter.width / 2, chartTop + chartHeight + 4),
      );
    }

    // Y-axis min/max labels
    for (final value in {minRating.round(), maxRating.round()}) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(0, yFor(value) - labelPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) =>
      oldDelegate.entries != entries;
}
