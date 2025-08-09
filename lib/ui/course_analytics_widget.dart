import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/stream_item.dart';
import 'package:school_management/model_class/submission.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class CourseAnalyticsWidget extends StatefulWidget {
  const CourseAnalyticsWidget({super.key});

  @override
  State<CourseAnalyticsWidget> createState() => _CourseAnalyticsWidgetState();
}

class _CourseAnalyticsWidgetState extends State<CourseAnalyticsWidget> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _error;

  // Data holders
  List<StreamItem>? _streamItems;
  List<Submission>? _submissions;
  List<SchoolClass>? _classes;
  DateTimeRange? _selectedDateRange;

  // Calculated metrics
  Map<String, int> _postsPerClass = {};
  Map<String, int> _assignmentsPerWeek = {};
  int _totalResponses = 0;
  Map<String, int> _gradeDistribution = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _authService.fetchAllStreamItems(),
        _authService.fetchAllSubmissions(),
        _authService.fetchAllSchoolClasses(),
      ]);

      _streamItems = results[0] as List<StreamItem>;
      _submissions = results[1] as List<Submission>;
      _classes = results[2] as List<SchoolClass>;

      _calculateMetrics();
    } catch (e) {
      developer.log('Error fetching analytics data: $e',
          name: 'CourseAnalytics');
      if (mounted) {
        setState(() {
          _error = 'Failed to load analytics data.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, now.month, now.day);
    final lastDate = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
              start: now.subtract(const Duration(days: 30)), end: now),
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _calculateMetrics(); // Recalculate with the new date range
    }
  }

  void _calculateMetrics() {
    if (_streamItems == null || _submissions == null || _classes == null)
      return;

    List<StreamItem> filteredStreamItems = _streamItems!;
    List<Submission> filteredSubmissions = _submissions!;

    if (_selectedDateRange != null) {
      final endDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59);
      filteredStreamItems = _streamItems!
          .where((item) =>
              !item.timestamp.isBefore(_selectedDateRange!.start) &&
              !item.timestamp.isAfter(endDate))
          .toList();
      // Assumes Submission model has a 'submittedAt' DateTime field. Adjust if needed.
      filteredSubmissions = _submissions!
          .where((submission) =>
              !submission.submissionTimestamp
                  .isBefore(_selectedDateRange!.start) &&
              !submission.submissionTimestamp.isAfter(endDate))
          .toList();
    }

    // 1. Posts per class
    final posts = filteredStreamItems
        .where((item) => item.type == 'announcement')
        .toList();
    final postsPerClassMap = <String, int>{};
    for (var post in posts) {
      final className = _classes
              ?.firstWhere((c) => c.classId == post.classId,
                  orElse: () => SchoolClass(
                      classId: '',
                      className: 'Unknown',
                      subjects: const [],
                      status: '',
                      createdAt: 0,
                      teacherId: null,
                      teacherName: null))
              .className ??
          'Unknown';
      postsPerClassMap[className] = (postsPerClassMap[className] ?? 0) + 1;
    }
    _postsPerClass = postsPerClassMap;

    // 2. Assignments per week
    final assignments =
        filteredStreamItems.where((item) => item.type == 'assignment').toList();
    final assignmentsPerWeekMap = SplayTreeMap<String, int>();
    for (var assignment in assignments) {
      // `assignment.timestamp` is already a DateTime object
      final date = assignment.timestamp;
      final firstDayOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(firstDayOfWeek);
      assignmentsPerWeekMap[weekKey] =
          (assignmentsPerWeekMap[weekKey] ?? 0) + 1;
    }
    _assignmentsPerWeek = assignmentsPerWeekMap;

    // 3. Student responses
    _totalResponses = filteredSubmissions.length;

    // 4. Grade distribution
    final gradedSubmissions = filteredSubmissions
        .where((s) => s.grade != null && s.grade!.isNotEmpty)
        .toList();
    final gradeDistributionMap = <String, int>{};
    for (var submission in gradedSubmissions) {
      final grade = submission.grade!;
      gradeDistributionMap[grade] = (gradeDistributionMap[grade] ?? 0) + 1;
    }
    _gradeDistribution = gradeDistributionMap;
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Course Analytics'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Text(_error!,
                              style: TextStyle(color: Colors.red.shade900))),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Course Analytics',
                              style: Theme.of(context).textTheme.headlineSmall),
                          _buildDateRangeFilter(),
                          const Divider(),
                          _buildMetricTile(
                              'Total Student Responses', '$_totalResponses'),
                          const SizedBox(height: 16),
                          _buildBarChart('Posts per Class', _postsPerClass),
                          const SizedBox(height: 16),
                          _buildBarChart(
                              'Assignments per Week', _assignmentsPerWeek),
                          const SizedBox(height: 16),
                          _buildPieChart(
                              'Grade Distribution', _gradeDistribution),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final rangeText = _selectedDateRange == null
        ? 'All Time'
        : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Date Range:', style: Theme.of(context).textTheme.titleMedium),
          TextButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(rangeText),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBarChart(String title, Map<String, int> data) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('No data available.'),
        ],
      );
    }

    final barGroups = data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: mapEntry.value.toDouble(),
            color: Colors.blue,
            width: 16,
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (data.values.reduce((a, b) => a > b ? a : b) * 1.2)
                  .toDouble(),
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.keys.length) {
                        String titleText = data.keys.elementAt(index);
                        if (title.contains('Assignments')) {
                          try {
                            final date = DateTime.parse(titleText);
                            titleText =
                                "W/o ${DateFormat('MMM d').format(date)}";
                          } catch (_) {
                            // ignore, use original key
                          }
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Text(titleText,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 38,
                  ),
                ),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(String title, Map<String, int> data) {
    if (data.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('No graded submissions available.'),
        ],
      );
    }

    final total = data.values.fold(0, (sum, item) => sum + item);
    final List<Color> colors = [
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.cyan
    ];

    final sections = data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final mapEntry = entry.value;
      final percentage = (mapEntry.value / total) * 100;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: mapEntry.value.toDouble(),
        title: '${mapEntry.key}\n(${percentage.toStringAsFixed(1)}%)',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }
}
