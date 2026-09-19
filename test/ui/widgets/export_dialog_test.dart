import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/services/analytics_export_service.dart';
import 'package:shinjuu_league/ui/widgets/export_dialog.dart';

void main() {
  group('ExportDialog', () {
    final testFields = [
      'timestamp',
      'userId',
      'action',
      'resourceType',
      'resourceId',
      'details',
    ];

    final testData = [
      {
        'timestamp': '2026-09-01T10:00:00Z',
        'userId': 'user_001',
        'action': 'CREATE',
        'resourceType': 'feature',
        'resourceId': 'feat_001',
        'details': 'Created feature X',
      },
      {
        'timestamp': '2026-09-01T11:00:00Z',
        'userId': 'user_002',
        'action': 'UPDATE',
        'resourceType': 'feature',
        'resourceId': 'feat_002',
        'details': 'Updated feature Y',
      },
    ];

    testWidgets('renders dialog with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Export Analytics Data'), findsOneWidget);
      expect(find.text('Export Format'), findsOneWidget);
      expect(find.text('Select Fields to Include'), findsOneWidget);
    });

    testWidgets('can select different export formats', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find and tap JSON format
      final jsonChip = find.byWidgetPredicate(
        (widget) =>
            widget is ChoiceChip &&
            widget.label is Text &&
            (widget.label as Text).data == 'JSON',
      );
      expect(jsonChip, findsOneWidget);

      await tester.tap(jsonChip);
      await tester.pumpAndSettle();

      // Verify JSON is selected (should have selected: true)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ChoiceChip &&
              widget.selected == true &&
              widget.label is Text &&
              (widget.label as Text).data == 'JSON',
        ),
        findsOneWidget,
      );
    });

    testWidgets('can select/deselect fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find checkbox for 'details' field
      final detailsCheckbox = find.byWidgetPredicate(
        (widget) =>
            widget is CheckboxListTile &&
            widget.title is Text &&
            (widget.title as Text).data == 'details',
      );

      expect(detailsCheckbox, findsOneWidget);

      // 'details' is the last field in a scrollable list inside the dialog,
      // so it can render below the visible viewport - scroll it into view
      // before tapping, or the tap offset misses it entirely.
      await tester.ensureVisible(detailsCheckbox);
      await tester.pumpAndSettle();

      // Tap to select
      await tester.tap(detailsCheckbox);
      await tester.pumpAndSettle();

      // Verify checkbox is now checked
      final checkedCheckbox = find.byWidgetPredicate(
        (widget) =>
            widget is CheckboxListTile &&
            widget.value == true &&
            widget.title is Text &&
            (widget.title as Text).data == 'details',
      );

      expect(checkedCheckbox, findsOneWidget);
    });

    testWidgets('displays file size preview', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Look for preview section
      expect(find.text('Preview'), findsOneWidget);
      expect(find.textContaining('Records:'), findsOneWidget);
      expect(find.textContaining('Fields:'), findsOneWidget);
      expect(find.textContaining('Est. Size:'), findsOneWidget);
    });

    testWidgets('shows error when no fields selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Deselect all fields by default ones
      for (final field in [
        'timestamp',
        'userId',
        'action',
        'resourceType',
        'resourceId',
      ]) {
        final checkbox = find.byWidgetPredicate(
          (widget) =>
              widget is CheckboxListTile &&
              widget.title is Text &&
              (widget.title as Text).data == field,
        );

        if (checkbox.evaluate().isNotEmpty) {
          // The field list scrolls, so later entries can render below the
          // visible viewport - scroll each into view before tapping it.
          await tester.ensureVisible(checkbox);
          await tester.pumpAndSettle();
          await tester.tap(checkbox);
          await tester.pumpAndSettle();
        }
      }

      // Try to export with no fields
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data?.contains('select at least one field') == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('export button calls onExport with correct data', (tester) async {
      ExportOptions? capturedOptions;
      String? capturedFileName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportDialog(
                        availableFields: testFields,
                        data: testData,
                        onExport: (options, fileName) {
                          capturedOptions = options;
                          capturedFileName = fileName;
                        },
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Change format to JSON
      final jsonChip = find.byWidgetPredicate(
        (widget) =>
            widget is ChoiceChip &&
            widget.label is Text &&
            (widget.label as Text).data == 'JSON',
      );
      await tester.tap(jsonChip);
      await tester.pumpAndSettle();

      // Click export
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Verify data was passed correctly
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.format, equals(ExportFormat.json));
      expect(capturedFileName, isNotNull);
      expect(capturedFileName!.endsWith('.json'), isTrue);
    });
  });

  group('ExportFormatDialog', () {
    testWidgets('renders dialog with format options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportFormatDialog(
                        onCSV: () {},
                        onJSON: () {},
                        onText: () {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Export Format'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('CSV option calls onCSV callback', (tester) async {
      bool csvCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportFormatDialog(
                        onCSV: () => csvCalled = true,
                        onJSON: () {},
                        onText: () {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap CSV option
      final csvOption = find.byWidgetPredicate(
        (widget) =>
            widget is ListTile &&
            widget.title is Text &&
            (widget.title as Text).data == 'CSV',
      );

      await tester.tap(csvOption);
      await tester.pumpAndSettle();

      expect(csvCalled, isTrue);
    });

    testWidgets('schedule report button visible when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportFormatDialog(
                        onCSV: () {},
                        onJSON: () {},
                        onText: () {},
                        onSchedule: () {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Report'), findsOneWidget);
    });

    testWidgets('schedule report button not visible when not provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ExportFormatDialog(
                        onCSV: () {},
                        onJSON: () {},
                        onText: () {},
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Report'), findsNothing);
    });
  });
}
