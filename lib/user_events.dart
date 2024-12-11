import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class EventPage extends StatefulWidget {
  final String? userMail;

  const EventPage({Key? key, required this.userMail}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late Future<Map<DateTime, List<Map<String, dynamic>>>> _eventsFuture;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<Map<DateTime, List<Map<String, dynamic>>>> fetchAndOrganizeEvents() async {
    if (widget.userMail == null) {
      throw Exception('User email is null');
    }

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userMail)
        .collection('events')
        .get();

    if (snapshot.docs.isEmpty) {
      return {};
    }

    Map<DateTime, List<Map<String, dynamic>>> eventsByDate = {};

    for (var doc in snapshot.docs) {
      var eventData = doc.data();

      try {
        DateTime eventDate = DateTime.parse(eventData['date']);

        DateTime dateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (!eventsByDate.containsKey(dateOnly)) {
          eventsByDate[dateOnly] = [];
        }
        eventsByDate[dateOnly]!.add(eventData);
      } catch (e) {
        print('Error parsing date for event: $e');
      }
    }

    return eventsByDate;
  }

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchAndOrganizeEvents();
    _selectedDay = _focusedDay;
  }

  List<Widget> _buildEventList(DateTime day, Map<DateTime, List<Map<String, dynamic>>> events) {
    final dayEvents = events[day] ?? [];
    return dayEvents.map((event) {
      return ListTile(
        title: Text(event['name'] ?? 'Unnamed Event'),
        subtitle: Text('Date: ${event['date']}'),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events for ${widget.userMail ?? "User"}'),
      ),
      body: FutureBuilder<Map<DateTime, List<Map<String, dynamic>>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No events found.'));
          }

          final events = snapshot.data!;

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  DateTime normalizedSelectedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
                  DateTime normalizedCurrentDay = DateTime(day.year, day.month, day.day);
                  return isSameDay(normalizedSelectedDay, normalizedCurrentDay);
                },
                eventLoader: (day) {
                  DateTime normalizedDay = DateTime(day.year, day.month, day.day);
                  print("Loading events for day: ${normalizedDay.toIso8601String()}");
                  return events[normalizedDay] ?? [];
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },

                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),

              Expanded(
                child: ListView(
                  children: _buildEventList(_selectedDay!, events),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
