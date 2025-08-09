import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/attendance_record.dart';
import 'package:school_management/providers/attendance_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:school_management/widgets/gradient_container.dart';

class AttendanceList extends ConsumerStatefulWidget {
  final String classId;

  const AttendanceList({super.key, required this.classId});

  @override
  ConsumerState<AttendanceList> createState() => _AttendanceListState();
}

class _AttendanceListState extends ConsumerState<AttendanceList> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, AttendanceStatus> _attendanceStatusByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green.shade700;
      case AttendanceStatus.late:
        return Colors.orange.shade700;
      case AttendanceStatus.absentExcused:
        return Colors.red.shade400;
      case AttendanceStatus.absentUnexcused:
        return Colors.red.shade800;
      case AttendanceStatus.holiday:
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync =
        ref.watch(studentAttendanceProvider(widget.classId));

    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Attendance'),
        ),
        body: attendanceAsync.when(
          data: (records) {
            _attendanceStatusByDate = {
              for (var record in records)
                DateTime(record.date.year, record.date.month, record.date.day):
                    record.status
            };

            final presentCount = records
                .where((r) =>
                    r.status == AttendanceStatus.present &&
                    r.date.month == _focusedDay.month)
                .length;
            final absentCount = records
                .where((r) =>
                    (r.status == AttendanceStatus.absentExcused ||
                        r.status == AttendanceStatus.absentUnexcused) &&
                    r.date.month == _focusedDay.month)
                .length;
            final holidayCount = records
                .where((r) =>
                    r.status == AttendanceStatus.holiday &&
                    r.date.month == _focusedDay.month)
                .length;

            final selectedDayRecords = records
                .where((record) => isSameDay(record.date, _selectedDay))
                .toList();

            return SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    child: TableCalendar(
                      headerStyle: const HeaderStyle(
                        titleTextStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0),
                        titleCentered: true,
                        formatButtonVisible: false,
                      ),
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final status = _attendanceStatusByDate[
                              DateTime(date.year, date.month, date.day)];
                          if (status != null) {
                            return Positioned(
                              bottom: 1,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryTile('Present', presentCount.toString(),
                            Colors.green.shade100),
                        _buildSummaryTile('Absent', absentCount.toString(),
                            Colors.red.shade100),
                        _buildSummaryTile('Holidays', holidayCount.toString(),
                            Colors.blue.shade100),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  _buildLegend(),
                  const SizedBox(height: 8.0),
                  if (_selectedDay != null)
                    ...selectedDayRecords.map((record) => Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: ListTile(
                            title: Text(DateFormat.yMMMd().format(record.date)),
                            trailing: Text(
                              record.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(record.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String title, String value, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Present', Colors.green.shade700),
          _buildLegendItem('Absent', Colors.red.shade400),
          _buildLegendItem('Holiday', Colors.blue.shade600),
          _buildLegendItem('Late', Colors.orange.shade700),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
