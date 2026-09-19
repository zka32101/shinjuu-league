import 'package:flutter/material.dart';
import 'package:shinjuu_league/services/analytics_export_service.dart';
import 'package:shinjuu_league/services/scheduled_report_service.dart';

/// Export dialog for analytics data
class ExportDialog extends StatefulWidget {
  final List<String> availableFields;
  final List<Map<String, dynamic>> data;
  final Function(ExportOptions, String fileName) onExport;
  final VoidCallback? onScheduleReport;

  const ExportDialog({
    required this.availableFields,
    required this.data,
    required this.onExport,
    this.onScheduleReport,
    Key? key,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late ExportFormat _selectedFormat;
  late Set<String> _selectedFields;
  late bool _includeMetadata;
  late bool _prettyPrint;
  late String _customFileName;
  late ReportFrequency? _scheduleFrequency;

  @override
  void initState() {
    super.initState();
    _selectedFormat = ExportFormat.csv;
    _selectedFields = Set.from([
      'timestamp',
      'userId',
      'action',
      'resourceType',
      'resourceId',
    ].where((f) => widget.availableFields.contains(f)));
    _includeMetadata = true;
    _prettyPrint = true;
    _customFileName = 'analytics-export';
    _scheduleFrequency = null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Analytics Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            _buildFormatSection(),
            const SizedBox(height: 20),

            // Field selection
            _buildFieldSelectionSection(),
            const SizedBox(height: 20),

            // Options
            _buildOptionsSection(),
            const SizedBox(height: 20),

            // File name
            _buildFileNameSection(),
            const SizedBox(height: 20),

            // Preview
            _buildPreviewSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.onScheduleReport != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onScheduleReport!();
            },
            child: const Text('Schedule Report'),
          ),
        ElevatedButton(
          onPressed: _export,
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export Format',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: ExportFormat.values.map((format) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_getFormatLabel(format)),
                  selected: _selectedFormat == format,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFormat = format);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFieldSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Fields to Include',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Column(
              children: widget.availableFields.map((field) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(field),
                  value: _selectedFields.contains(field),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedFields.add(field);
                      } else {
                        _selectedFields.remove(field);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include Metadata'),
          value: _includeMetadata,
          onChanged: (selected) {
            setState(() => _includeMetadata = selected ?? true);
          },
        ),
        if (_selectedFormat == ExportFormat.json)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pretty Print JSON'),
            value: _prettyPrint,
            onChanged: (selected) {
              setState(() => _prettyPrint = selected ?? true);
            },
          ),
      ],
    );
  }

  Widget _buildFileNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter file name',
            border: const OutlineInputBorder(),
            suffixText: _getFileExtension(_selectedFormat),
          ),
          onChanged: (value) {
            setState(() => _customFileName = value);
          },
          controller: TextEditingController(text: _customFileName),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final fileSize = AnalyticsExportService.estimateFileSize(
      widget.data,
      _selectedFormat,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Records: ${widget.data.length}'),
          Text('Fields: ${_selectedFields.length}'),
          Text('Est. Size: ${_formatFileSize(fileSize)}'),
          Text(
            'File: $_customFileName${_getFileExtension(_selectedFormat)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getFormatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.text:
        return 'Text';
    }
  }

  String _getFileExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.json:
        return '.json';
      case ExportFormat.text:
        return '.txt';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _export() {
    if (_selectedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one field')),
      );
      return;
    }

    final options = ExportOptions(
      format: _selectedFormat,
      selectedFields: _selectedFields.toList(),
      includeMetadata: _includeMetadata,
      prettyPrint: _prettyPrint,
      customFileName: _customFileName,
    );

    final fileName = AnalyticsExportService.generateFileName(options);

    widget.onExport(options, fileName);
    Navigator.pop(context);
  }
}

/// Export format selection dialog
class ExportFormatDialog extends StatelessWidget {
  final VoidCallback onCSV;
  final VoidCallback onJSON;
  final VoidCallback onText;
  final VoidCallback? onSchedule;

  const ExportFormatDialog({
    required this.onCSV,
    required this.onJSON,
    required this.onText,
    this.onSchedule,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Format'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('CSV'),
              subtitle: const Text('Spreadsheet format'),
              onTap: () {
                Navigator.pop(context);
                onCSV();
              },
            ),
            ListTile(
              title: const Text('JSON'),
              subtitle: const Text('Structured data format'),
              onTap: () {
                Navigator.pop(context);
                onJSON();
              },
            ),
            ListTile(
              title: const Text('Text'),
              subtitle: const Text('Human-readable format'),
              onTap: () {
                Navigator.pop(context);
                onText();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (onSchedule != null)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSchedule!();
            },
            child: const Text('Schedule Report'),
          ),
      ],
    );
  }
}
