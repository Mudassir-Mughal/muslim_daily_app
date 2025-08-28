import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../Services/timezone.dart'; // Adjust path if needed

class IslamicEventType {
  final String name;
  final int hMonth;
  final int hDay;
  IslamicEventType({required this.name, required this.hMonth, required this.hDay});
}

final List<IslamicEventType> islamicEventTypes = [
  IslamicEventType(name: "Ashura", hMonth: 1, hDay: 10),
  IslamicEventType(name: "Ashura", hMonth: 1, hDay: 9),
  IslamicEventType(name: "Eid Milad un Nabi", hMonth: 3, hDay: 12),
  IslamicEventType(name: "Ramadhan Start", hMonth: 9, hDay: 1),
  IslamicEventType(name: "Eid ul Fitr", hMonth: 10, hDay: 1),
  IslamicEventType(name: "Eid ul Azha", hMonth: 12, hDay: 10),
  IslamicEventType(name: "Islamic New Year", hMonth: 1, hDay: 1),
  IslamicEventType(name: "Hajj", hMonth: 12, hDay: 9),
];

class HijriCalendarPage extends StatefulWidget {
  @override
  _HijriCalendarPageState createState() => _HijriCalendarPageState();
}

class _HijriCalendarPageState extends State<HijriCalendarPage> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  HijriCalendar? _selectedHijri;
  IslamicEventType? _selectedEventType;

  @override
  void initState() {
    super.initState();
    final localTime = TimeZoneService.getLocalDateTime();
    _focusedDay = localTime;
    _selectedDay = localTime;
    _selectedHijri = getAdjustedHijriFromDate(localTime);
    _selectedEventType = getEventTypeForHijri(_selectedHijri!);
  }

  HijriCalendar getAdjustedHijriFromDate(DateTime date) {
    HijriCalendar hijri = HijriCalendar.fromDate(date);
    if (TimeZoneService.shouldAdjustHijriDate()) {
      if (hijri.hDay == 1) {
        hijri.hMonth -= 1;
        if (hijri.hMonth < 1) {
          hijri.hMonth = 12;
          hijri.hYear -= 1;
        }
        hijri.hDay = hijri.getDaysInMonth(hijri.hYear, hijri.hMonth);
      } else {
        hijri.hDay -= 1;
      }
    }
    return hijri;
  }

  IslamicEventType? getEventTypeForHijri(HijriCalendar hijri) {
    try {
      return islamicEventTypes.firstWhere(
            (eventType) =>
        eventType.hMonth == hijri.hMonth &&
            eventType.hDay == hijri.hDay,
      );
    } catch (e) {
      return null;
    }
  }

  String getFormattedGregorian(DateTime date) =>
      DateFormat('dd MMMM yyyy').format(date);

  String getFormattedHijri(HijriCalendar hijri) =>
      '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}';

  String getDayName(DateTime date) => DateFormat('EEEE').format(date);

  // For upcoming event, get the next event after today in this month
  IslamicEventType? getUpcomingEvent(DateTime current) {
    final todayHijri = getAdjustedHijriFromDate(current);
    final events = islamicEventTypes.where((e) =>
    (e.hMonth > todayHijri.hMonth) ||
        (e.hMonth == todayHijri.hMonth && e.hDay >= todayHijri.hDay)
    ).toList();
    events.sort((a, b) {
      if (a.hMonth != b.hMonth) return a.hMonth.compareTo(b.hMonth);
      return a.hDay.compareTo(b.hDay);
    });
    return events.isNotEmpty ? events.first : null;
  }

  // For upcoming event Gregorian date
  DateTime? getUpcomingEventGregorianDate(IslamicEventType? event) {
    if (event == null) return null;
    DateTime date = _focusedDay;
    for (int i = 0; i < 370; i++) {
      final hijri = getAdjustedHijriFromDate(date);
      if (hijri.hMonth == event.hMonth && hijri.hDay == event.hDay) {
        return date;
      }
      date = date.add(Duration(days: 1));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final greenLight = const Color(0xFFD6F7E0);
    final greenMedium = const Color(0xFF7ED9A4);
    final greenDark = const Color(0xFF18895B);
    final calendarBG = "assets/calender_bg.png"; // Use your asset

    final upcomingEvent = getUpcomingEvent(_focusedDay);
    final upcomingEventDate = getUpcomingEventGregorianDate(upcomingEvent);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 0, 0),
              child: Text(
                "Calendar",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedHijri != null && _selectedDay != null)
              Column(
                children: [
                  Text(
                    'Islamic: ${getFormattedHijri(_selectedHijri!)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    getFormattedGregorian(_selectedDay!),
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            // CALENDAR CARD
            Center(
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
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                                    _selectedHijri = getAdjustedHijriFromDate(_focusedDay);
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
                                    '${getAdjustedHijriFromDate(_focusedDay).getLongMonthName()} ${getAdjustedHijriFromDate(_focusedDay).hYear}',
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
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                                    _selectedHijri = getAdjustedHijriFromDate(_focusedDay);
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
                        // This fixes the overflow/extra row issue!
                        SizedBox(
                          height: 275, // enough for 6 weeks
                          child: TableCalendar(
                            firstDay: DateTime(2000),
                            lastDay: DateTime(2100),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            calendarFormat: CalendarFormat.month,
                            startingDayOfWeek: StartingDayOfWeek.sunday,
                            headerVisible: false,
                            sixWeekMonthsEnforced: true, // Always 6 rows
                            shouldFillViewport: true,    // Fills available height
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
                                final hijri = getAdjustedHijriFromDate(day);
                                final isSelected = isSameDay(_selectedDay, day);
                                final isToday = isSameDay(day, DateTime.now());

                                Color bgColor;
                                if (isSelected) {
                                  bgColor = greenDark;
                                } else if (isToday) {
                                  bgColor = greenMedium;
                                } else {
                                  bgColor = Colors.white.withOpacity(0.5); // white circle for all dates
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
                                      hijri.hDay.toString(),
                                      style: TextStyle(
                                        color: isSelected || isToday ? Colors.white : greenDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              selectedBuilder: (context, day, focusedDay) {
                                final hijri = getAdjustedHijriFromDate(day);
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
                                      hijri.hDay.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              todayBuilder: (context, day, focusedDay) {
                                final hijri = getAdjustedHijriFromDate(day);
                                return Center(
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: greenMedium,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      hijri.hDay.toString(),
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
                                final isToday = DateFormat.E().format(_selectedDay ?? DateTime.now()) == text;
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
                            onDaySelected: (selectedDay, focusedDay) {
                              final selectedHijri = getAdjustedHijriFromDate(selectedDay);
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                _selectedHijri = selectedHijri;
                                _selectedEventType = getEventTypeForHijri(selectedHijri);
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
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
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: 24.0), // Adjust the value as you like
              child: Text(
                "Upcoming Events:",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 12),
            // UPCOMING EVENT CARD
            if (upcomingEvent != null && upcomingEventDate != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: greenMedium, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.event, size: 26, color: greenMedium),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              upcomingEvent.name,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: greenDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "${getAdjustedHijriFromDate(upcomingEventDate).hDay} ${getAdjustedHijriFromDate(upcomingEventDate).getLongMonthName()} ${getAdjustedHijriFromDate(upcomingEventDate).hYear} AH",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(upcomingEventDate),
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}