import 'dart:math';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/attendance_record.dart';
import 'package:school_management/services/auth_service.dart';
import 'dart:developer' as developer;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AttendanceReportsPage extends StatefulWidget {
  const AttendanceReportsPage({super.key});

  @override
  State<AttendanceReportsPage> createState() => _AttendanceReportsPageState();
}

class _AttendanceReportsPageState extends State<AttendanceReportsPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isExporting = false;
  List<AttendanceRecord> _allRecords = [];
  List<AttendanceRecord> _filteredRecords = [];

  // Filter state
  DateTimeRange? _selectedDateRange;
  String? _selectedClassId;
  String? _selectedStudentId;
  List<Map<String, String>> _availableClasses = [];
  List<Map<String, String>> _availableStudents = [];

  // Calculated Metrics
  double _overallAttendancePercentage = 0;
  int _totalAbsences = 0;
  int _totalLates = 0;
  Map<String, int> _absenceCountsByStudent = {};
  Map<String, int> _lateCountsByStudent = {};
  Map<String, double> _classWiseAttendance = {};

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 29)),
      end: DateTime.now(),
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch real attendance data from the AuthService
      _allRecords = await _authService.fetchAllAttendanceRecords();
      _prepareFilterData();
      _filterAndCalculateMetrics();
    } catch (e) {
      developer.log('Failed to load attendance reports: $e',
          name: 'AttendanceReportsPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load attendance data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _prepareFilterData() {
    if (_allRecords.isEmpty) return;

    final uniqueClasses = <String, String>{};
    final uniqueStudents = <String, String>{};

    for (final record in _allRecords) {
      uniqueClasses[record.classId] = record.className;
      uniqueStudents[record.studentId] = record.studentName;
    }

    setState(() {
      _availableClasses = uniqueClasses.entries
          .map((e) => {'id': e.key, 'name': e.value})
          .toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));

      _availableStudents = uniqueStudents.entries
          .map((e) => {'id': e.key, 'name': e.value})
          .toList()
        ..sort((a, b) => a['name']!.compareTo(b['name']!));
    });
  }

  void _filterAndCalculateMetrics() {
    if (_selectedDateRange == null) return;

    final endDate = DateTime(_selectedDateRange!.end.year,
        _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
    _filteredRecords = _allRecords.where((record) {
      final dateMatches = !record.date.isBefore(_selectedDateRange!.start) &&
          !record.date.isAfter(endDate);
      final classMatches =
          _selectedClassId == null || record.classId == _selectedClassId;
      final studentMatches =
          _selectedStudentId == null || record.studentId == _selectedStudentId;
      return dateMatches && classMatches && studentMatches;
    }).toList();

    _calculateOverallAttendance();
    _calculateAbsencesAndLates();
    _calculateClassWiseAttendance();
    setState(() {});
  }

  void _calculateOverallAttendance() {
    if (_filteredRecords.isEmpty) {
      _overallAttendancePercentage = 0;
      return;
    }
    final presentOrLate = _filteredRecords
        .where((r) =>
            r.status == AttendanceStatus.present ||
            r.status == AttendanceStatus.late)
        .length; // Corrected enum usage
    _overallAttendancePercentage =
        (presentOrLate / _filteredRecords.length) * 100;
  }

  void _calculateAbsencesAndLates() {
    _absenceCountsByStudent.clear();
    _lateCountsByStudent.clear();
    _totalAbsences = 0;
    _totalLates = 0;

    for (final record in _filteredRecords) {
      if (record.status == AttendanceStatus.absentExcused ||
          record.status == AttendanceStatus.absentUnexcused) {
        _absenceCountsByStudent[record.studentName] =
            (_absenceCountsByStudent[record.studentName] ?? 0) + 1;
        _totalAbsences++;
      } else if (record.status == AttendanceStatus.late) {
        _lateCountsByStudent[record.studentName] =
            (_lateCountsByStudent[record.studentName] ?? 0) + 1;
        _totalLates++;
      }
    }
  }

  void _calculateClassWiseAttendance() {
    _classWiseAttendance.clear();
    final recordsByClass = <String, List<AttendanceRecord>>{};
    for (final record in _filteredRecords) {
      (recordsByClass[record.className] ??= []).add(record);
    }

    recordsByClass.forEach((className, records) {
      if (records.isEmpty) {
        _classWiseAttendance[className] = 0;
      } else {
        final presentOrLate = records
            .where((r) =>
                r.status == AttendanceStatus.present ||
                r.status == AttendanceStatus.late)
            .length; // Corrected enum usage
        _classWiseAttendance[className] =
            (presentOrLate / records.length) * 100;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      initialDateRange: _selectedDateRange,
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _filterAndCalculateMetrics();
    }
  }

  Future<void> _exportToCsv() async {
    if (_filteredRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final List<List<dynamic>> rows = [];
      // Add header row
      rows.add(['Student Name', 'Class Name', 'Date', 'Status']);
      // Add data rows
      for (final record in _filteredRecords) {
        rows.add([
          record.studentName,
          record.className,
          DateFormat('yyyy-MM-dd').format(record.date),
          record.status.toString().split('.').last,
        ]);
      }

      final String csv = const ListToCsvConverter().convert(rows);

      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/attendance_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final File file = File(path);
      await file.writeAsString(csv);

      final xfile = XFile(path, name: 'attendance_report.csv');
      await Share.shareXFiles([xfile], text: 'Student Attendance Report');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar:
            AppBar(title: const Text('Student Attendance Reports'), actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _filteredRecords.isEmpty ? null : _exportToCsv,
              tooltip: 'Export to CSV',
            ),
        ]),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFiltersCard(),
                    const SizedBox(height: 16),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Class-wise Attendance'),
                    _buildClassWiseChart(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Absence Reports (Top 5)'),
                    _buildReportList(_absenceCountsByStudent, 'days absent'),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Late Arrivals (Top 5)'),
                    _buildReportList(_lateCountsByStudent, 'late arrivals'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final rangeText = _selectedDateRange == null
        ? 'Select Range'
        : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}'; // Corrected null check

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Date Range'),
              subtitle: Text(rangeText),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateRange,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _buildClassFilter(),
            const SizedBox(height: 12),
            _buildStudentFilter(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassFilter() {
    return DropdownButtonFormField<String?>(
      value: _selectedClassId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filter by Class',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.class_),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Classes'),
        ),
        ..._availableClasses.map((c) => DropdownMenuItem<String?>(
              value: c['id'],
              child: Text(c['name']!),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedClassId = value);
        _filterAndCalculateMetrics();
      },
    );
  }

  Widget _buildStudentFilter() {
    return DropdownButtonFormField<String?>(
      value: _selectedStudentId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filter by Student',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Students'),
        ),
        ..._availableStudents.map((s) => DropdownMenuItem<String?>(
              value: s['id'],
              child: Text(s['name']!),
            )),
      ],
      onChanged: (value) {
        setState(() => _selectedStudentId = value);
        _filterAndCalculateMetrics();
      },
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMetricCard(
            'Overall Attendance',
            '${_overallAttendancePercentage.toStringAsFixed(1)}%',
            Icons.pie_chart,
            Colors.green),
        _buildMetricCard('Total Absences', '$_totalAbsences', Icons.person_off,
            Colors.orange),
        _buildMetricCard(
            'Total Lates', '$_totalLates', Icons.watch_later, Colors.blue),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Flexible(
              child: Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildClassWiseChart() {
    if (_classWiseAttendance.isEmpty) {
      return const SizedBox(
          height: 100, child: Center(child: Text('No data for chart.')));
    }

    final barGroups =
        _classWiseAttendance.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: mapEntry.value,
            color: Colors.blue,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxY = _classWiseAttendance.values.isEmpty
        ? 100.0
        : _classWiseAttendance.values.reduce(max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY > 0 ? maxY * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String className =
                    _classWiseAttendance.keys.elementAt(group.x.toInt());
                return BarTooltipItem(
                  '$className\n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _classWiseAttendance.keys.length) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 4.0,
                      child: Text(_classWiseAttendance.keys.elementAt(index),
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 38,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: 20),
        ),
      ),
    );
  }

  Widget _buildReportList(Map<String, int> data, String unit) {
    if (data.isEmpty) {
      return const Card(child: ListTile(title: Text('No data available.')));
    }
    // Sort by count descending and take top 5
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sortedEntries.take(5);

    return Column(
      children: topEntries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(entry.key),
            trailing: Text(
              '${entry.value} $unit',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      }).toList(),
    );
  }
}
