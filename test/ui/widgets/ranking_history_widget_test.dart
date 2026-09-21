import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/ranking_service.dart';
import 'package:shinjuu_league/ui/widgets/ranking_history_widget.dart';

void main() {
  group('RankingHistoryWidget', () {
    testWidgets('shows an empty-state message with no season history', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RankingHistoryWidget(entries: [])),
        ),
      );

      expect(find.text('まだシーズン参加履歴がありません'), findsOneWidget);
    });

    testWidgets(
      'renders the trend chart and a tile per season without throwing',
      (tester) async {
        final entries = [
          SeasonHistoryEntry(
            seasonId: 'season-1',
            seasonName: 'Season 1',
            startedAt: DateTime(2026, 1, 1),
            startingRating: 1200,
            peakRating: 1400,
            finalRating: 1350,
            peakTier: 'Silver',
            seasonWins: 10,
            seasonLosses: 5,
          ),
          SeasonHistoryEntry(
            seasonId: 'season-2',
            seasonName: 'Season 2',
            startedAt: DateTime(2026, 3, 1),
            startingRating: 1350,
            peakRating: 1900,
            finalRating: 1850,
            peakTier: 'Gold',
            seasonWins: 20,
            seasonLosses: 8,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RankingHistoryWidget(entries: entries)),
          ),
        );

        expect(find.text('Season 1'), findsOneWidget);
        expect(find.text('Season 2'), findsOneWidget);
        expect(find.text('Gold'), findsWidgets);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders a single-season history without dividing by zero', (
      tester,
    ) async {
      final entries = [
        SeasonHistoryEntry(
          seasonId: 'season-1',
          seasonName: 'Season 1',
          startedAt: DateTime(2026, 1, 1),
          startingRating: 1200,
          peakRating: 1200,
          finalRating: 1200,
          peakTier: 'Bronze',
          seasonWins: 0,
          seasonLosses: 0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RankingHistoryWidget(entries: entries)),
        ),
      );

      expect(find.text('Season 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
