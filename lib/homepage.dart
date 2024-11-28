import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  final List<Map<String, dynamic>> people = [
    {
      'name': 'Mariam Hassan',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'events': {
        DateTime(2024, 12, 1): ['Mariam\'s Birthday Party'],
        DateTime(2024, 12, 10): ['Team Meeting']
      },
    },
    {
      'name': 'Mina George',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'events': {}, // No events for Mina
    },
    {
      'name': 'Hazem Mohamed',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'events': {
        DateTime(2024, 12, 5): ['Project Launch'],
      },
    },
    {
      'name': 'Mazen Ali',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'events': {
        DateTime(2024, 12, 8): ['Wedding Anniversary'],
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upcoming Events')),
      body: ListView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          return PersonRow(person: people[index]);
        },
      ),
    );
  }
}

class PersonRow extends StatelessWidget {
  final Map<String, dynamic> person;

  PersonRow({required this.person});

  @override
  Widget build(BuildContext context) {
    final int upcomingEvents = person['events'].length;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(person['avatar']!),
        ),
        title: Text(person['name']!),
        trailing: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CalendarPage(
                  name: person['name']!,
                  events: person['events'],
                ),
              ),
            );
          },
          child: Badge(
            count: upcomingEvents,
          ),
        ),
        subtitle: Text(
          upcomingEvents > 0
              ? "Upcoming Events: $upcomingEvents"
              : "No Upcoming Events",
        ),
      ),
    );
  }
}

class Badge extends StatelessWidget {
  final int count;

  Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: count > 0 ? Colors.red : Colors.grey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 0 ? count.toString() : "0",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final String name;
  final Map<DateTime, List<String>> events;

  CalendarPage({required this.name, required this.events});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Events for ${widget.name}")),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return widget.events[normalizedDay] ?? [];
            },

            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              final events = widget.events[normalizedDay];

              String displayMessage;

              if (events != null && events.isNotEmpty) {
                // Join event names as a list (e.g., "Mariam's Birthday Party, Mina's Event")
                displayMessage = 'Events on ${selectedDay.toLocal()}: ${events.join(', ')}';
              } else {
                // If no events exist, show a message saying "No events"
                displayMessage = 'No events for ${selectedDay.toLocal()}';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(displayMessage),
                ),
              );
            },


          ),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Selected Day: ${_selectedDay!.toLocal()}",
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
