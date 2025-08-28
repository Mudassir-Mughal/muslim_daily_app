import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:muslim_daily/Screens/topbar.dart'; // Import your custom app bar

final List<String> prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

class NamazTrackerScreen extends StatefulWidget {
  NamazTrackerScreen();

  @override
  State<NamazTrackerScreen> createState() => _NamazTrackerScreenState();
}

class _NamazTrackerScreenState extends State<NamazTrackerScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime calendarRefDate = DateTime.now();
  Map<String, Map<String, bool>> allStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    allStatuses = {};
    final data = prefs.getString('namaz_statuses');
    if (data != null) {
      final jsonMap = jsonDecode(data) as Map<String, dynamic>;
      jsonMap.forEach((dateStr, prayersMap) {
        allStatuses[dateStr] = Map<String, bool>.from(prayersMap);
      });
    }
    setState(() {});
  }

  Future<void> _saveStatusForDate(String dateStr, Map<String, bool> status) async {
    allStatuses[dateStr] = status;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('namaz_statuses', jsonEncode(allStatuses));
    setState(() {});
  }

  String _dateString(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  Map<String, bool> _getStatusForDate(DateTime date) {
    final dstr = _dateString(date);
    return allStatuses[dstr] ?? {for (var p in prayers) p: false};
  }

  bool _isDayCompleted(DateTime day) {
    final status = _getStatusForDate(day);
    return prayers.every((prayer) => status[prayer] == true);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white;
    final selectedCircleColor = Color(0xFF00B2FF); // Blue for selected/ticked
    final outlinedCircleColor = Color(0xFF0D4746);
    final textColor = Color(0xFF0D4746);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          IslamicTopBar(
            title: "Namaz Tracker",
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 16),
                  _buildDateHeader(selectedDate, textColor),
                  SizedBox(height: 4),
                  _buildPrayerList(selectedDate, textColor, selectedCircleColor, outlinedCircleColor),
                  SizedBox(height: 18),
                  _buildCalendarWithHijriStyle(),
                  SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, Color textColor) {
    final hijriDate = ""; // If you want to add Islamic date, use a hijri package
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0), // or your desired left padding
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isSameDay(date, DateTime.now())
                  ? "Today, ${DateFormat('d MMMM y').format(date)}"
                  : DateFormat('EEEE, d MMMM yyyy').format(date),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
            ),
          ),
        ),
        if (hijriDate.isNotEmpty)
          Text(hijriDate, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
      ],
    );
  }

  Widget _buildPrayerList(DateTime date, Color textColor, Color iconColor, Color outlinedCircleColor) {
    final status = _getStatusForDate(date);

    final List<Map<String, dynamic>> prayerInfo = [
      {
        "name": "Fajr",
        "icon": "assets/fajr.png",
        "color": Color(0xFF6EC6F1),
      },
      {
        "name": "Dhuhr",
        "icon": "assets/dhuhr.png",
        "color": Color(0xFFF29E38),
      },
      {
        "name": "Asr",
        "icon": "assets/asr.png",
        "color": Color(0xFF8C80F8),
      },
      {
        "name": "Maghrib",
        "icon": "assets/maghrib.png",
        "color": Color(0xFFFF8C81),
      },
      {
        "name": "Isha",
        "icon": "assets/isha.png",
        "color": Color(0xFF3E65F9),
      },
    ];

    return Column(
      children: prayerInfo.map((info) {
        final prayer = info['name'] as String;
        return Card(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (info['color'] as Color).withOpacity(0.09),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  info['icon'] as String,
                  width: 24,
                  height: 24,
                  color: info['color'] as Color,
                ),
              ),
            ),
            title: Text(
              prayer,
              style: TextStyle(color: outlinedCircleColor, fontWeight: FontWeight.w500),
            ),
            trailing: Checkbox(
              value: status[prayer] ?? false,
              onChanged: date.isAfter(DateTime.now())
                  ? null
                  : (val) {
                final newStatus = {...status, prayer: val ?? false};
                _saveStatusForDate(_dateString(date), newStatus);
              },
              activeColor: info['color'] as Color,
              checkColor: Colors.white,
              side: BorderSide(color: info['color'] as Color, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarWithHijriStyle() {
    final greenMedium = const Color(0xFF7ED9A4);
    final greenDark = const Color(0xFF18895B);
    final calendarBG = "assets/calender_bg.png"; // Your asset path

    return Center(
      child: Container(
        width: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: greenMedium.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                calendarBG,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                width: 350,
                height: 350,
              ),
            ),
            Column(
              children: [
                // HEADER: Month name and navigation
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 8, right: 8, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() {
                            calendarRefDate = DateTime(calendarRefDate.year, calendarRefDate.month - 1, calendarRefDate.day);
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.chevron_left, size: 28, color: Color(0xFF18895B)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_rounded, color: greenDark, size: 18),
                          SizedBox(width: 6),
                          Text(
                            '${DateFormat.MMMM().format(calendarRefDate)} ${calendarRefDate.year}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: greenDark,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          setState(() {
                            calendarRefDate = DateTime(calendarRefDate.year, calendarRefDate.month + 1, calendarRefDate.day);
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(Icons.chevron_right, size: 28, color: Color(0xFF18895B)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 275,
                  child: TableCalendar(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: calendarRefDate,
                    selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    headerVisible: false,
                    sixWeekMonthsEnforced: true,
                    shouldFillViewport: true,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekendStyle: TextStyle(
                        color: greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                      weekdayStyle: TextStyle(
                        color: greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      cellMargin: EdgeInsets.all(0),
                      tablePadding: EdgeInsets.zero,
                      todayDecoration: BoxDecoration(
                        color: greenMedium,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: greenDark,
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      weekendDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      disabledDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: TextStyle(
                        color: greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendTextStyle: TextStyle(
                        color: greenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        final isSelected = isSameDay(selectedDate, day);
                        final isToday = isSameDay(day, DateTime.now());
                        final isCompleted = _isDayCompleted(day);

                        Color bgColor;
                        if (isCompleted || isSelected) {
                          bgColor = greenDark;
                        } else if (isToday) {
                          bgColor = greenMedium;
                        } else {
                          bgColor = Colors.white.withOpacity(0.5);
                        }

                        return Center(
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: (isSelected || isToday || isCompleted)
                                    ? Colors.white
                                    : greenDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, day, focusedDay) {
                        return Center(
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: greenDark,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      todayBuilder: (context, day, focusedDay) {
                        final isCompleted = _isDayCompleted(day);
                        final isSelected = isSameDay(selectedDate, day);
                        Color bgColor;
                        if (isCompleted || isSelected) {
                          bgColor = greenDark;
                        } else {
                          bgColor = greenMedium;
                        }
                        return Center(
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: bgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      dowBuilder: (context, day) {
                        final text = DateFormat.E().format(day);
                        final isToday = DateFormat.E().format(selectedDate) == text;
                        return Center(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isToday ? greenDark : greenDark.withOpacity(0.7),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDate = selected;
                        calendarRefDate = focused;
                      });
                    },
                    onPageChanged: (focused) {
                      setState(() {
                        calendarRefDate = focused;
                      });
                    },
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}