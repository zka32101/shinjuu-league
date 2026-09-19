import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';
import 'package:shinjuu_league/viewmodels/report_schedule_viewmodel.dart';

/// Screen for managing scheduled reports
class ScheduledReportsScreen extends ConsumerStatefulWidget {
  const ScheduledReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScheduledReportsScreen> createState() =>
      _ScheduledReportsScreenState();
}

class _ScheduledReportsScreenState
    extends ConsumerState<ScheduledReportsScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: Load scheduled reports for current user
    // ref.read(reportScheduleViewModelProvider.notifier).loadScheduledReports(userId);
  }

  @override
  Widget build(BuildContext context) {
    // final reportState = ref.watch(reportScheduleViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled Reports'),
        centerTitle: true,
      ),
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateReportDialog,
        tooltip: 'Create Scheduled Report',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    // TODO: Replace with actual state when provider is set up
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No scheduled reports',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateReportDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Report'),
          ),
        ],
      ),
    );
  }

  void _showCreateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateReportDialog(
        onSubmit: (name, format, selectedFields, frequency, recipients) {
          // TODO: Submit to view model
        },
      ),
    );
  }
}

/// Dialog for creating a new scheduled report
class _CreateReportDialog extends StatefulWidget {
  final Function(
    String name,
    ReportExportFormat format,
    List<String> selectedFields,
    ReportFrequency frequency,
    List<String> recipients,
  ) onSubmit;

  const _CreateReportDialog({
    required this.onSubmit,
    Key? key,
  }) : super(key: key);

  @override
  State<_CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<_CreateReportDialog> {
  late TextEditingController _nameController;
  late TextEditingController _recipientsController;
  late ReportExportFormat _selectedFormat;
  late ReportFrequency _selectedFrequency;
  late Set<String> _selectedFields;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _recipientsController = TextEditingController();
    _selectedFormat = ReportExportFormat.csv;
    _selectedFrequency = ReportFrequency.daily;
    _selectedFields = {
      'timestamp',
      'userId',
      'action',
      'resourceType',
      'resourceId',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _recipientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Scheduled Report'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Report Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Format selection
            const Text(
              'Export Format',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReportExportFormat>(
              segments: const [
                ButtonSegment(label: Text('CSV'), value: ReportExportFormat.csv),
                ButtonSegment(
                    label: Text('JSON'), value: ReportExportFormat.json),
                ButtonSegment(label: Text('Text'), value: ReportExportFormat.text),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (selection) {
                setState(() => _selectedFormat = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Frequency selection
            const Text(
              'Report Frequency',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReportFrequency>(
              segments: const [
                ButtonSegment(label: Text('Daily'), value: ReportFrequency.daily),
                ButtonSegment(
                    label: Text('Weekly'), value: ReportFrequency.weekly),
                ButtonSegment(
                    label: Text('Monthly'), value: ReportFrequency.monthly),
              ],
              selected: {_selectedFrequency},
              onSelectionChanged: (selection) {
                setState(() => _selectedFrequency = selection.first);
              },
            ),
            const SizedBox(height: 16),

            // Recipient emails
            TextField(
              controller: _recipientsController,
              decoration: InputDecoration(
                labelText: 'Recipient Emails',
                hintText: 'email1@example.com, email2@example.com',
                border: const OutlineInputBorder(),
                helperText: 'Separate multiple emails with commas',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a report name')),
      );
      return;
    }

    if (_recipientsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one email')),
      );
      return;
    }

    final emails = _recipientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    widget.onSubmit(
      _nameController.text,
      _selectedFormat,
      _selectedFields.toList(),
      _selectedFrequency,
      emails,
    );

    Navigator.pop(context);
  }
}

/// Widget displaying a single scheduled report card
class ScheduledReportCard extends StatelessWidget {
  final ScheduledReport report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExecute;

  const ScheduledReportCard({
    required this.report,
    required this.onEdit,
    required this.onDelete,
    required this.onExecute,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ScheduledReportService.getFormatLabel(report.format),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(ScheduledReportService.getFrequencyLabel(
                    report.frequency,
                  )),
                  backgroundColor: _getFrequencyColor(report.frequency),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipients: ${report.recipientEmails.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next: ${_formatDateTime(report.nextExecutionAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Fields: ${report.selectedFields.length}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDateTime(report.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onExecute,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Execute'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFrequencyColor(ReportFrequency frequency) {
    switch (frequency) {
      case ReportFrequency.once:
        return Colors.grey;
      case ReportFrequency.daily:
        return Colors.blue;
      case ReportFrequency.weekly:
        return Colors.orange;
      case ReportFrequency.monthly:
        return Colors.green;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'soon';
    }
  }
}
