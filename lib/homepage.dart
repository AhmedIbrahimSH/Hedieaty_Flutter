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

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Map<String, dynamic>> people = [
    {
      'name': 'Mariam Hassan',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'events': {
        DateTime(2024, 12, 1): ['Mariam\'s Birthday Party'],
        DateTime(2024, 12, 10): ['Team Meeting']
      },
      'gifts': ['Handbag', 'Smartwatch', 'Gift Card'],
    },
    {
      'name': 'Mina George',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'events': {},
      'gifts': ['Perfume', 'Laptop Sleeve'],
    },
    {
      'name': 'Hazem Mohamed',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'events': {
        DateTime(2024, 12, 5): ['Project Launch'],
      },
      'gifts': ['Bluetooth Speaker', 'Camera'],
    },
    {
      'name': 'Mazen Ali',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'events': {
        DateTime(2024, 12, 8): ['Wedding Anniversary'],
      },
      'gifts': ['Watch', 'Shoes'],
    },
  ];

  List<Map<String, dynamic>> filteredPeople = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredPeople = people; // Initialize with all people
  }

  void _filterPeople(String query) {
    setState(() {
      filteredPeople = people
          .where((person) => person['name']
          .toLowerCase()
          .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: _filterPeople,
              decoration: InputDecoration(
                hintText: "Search for your friend's list",
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPeople.length,
              itemBuilder: (context, index) {
                return PersonRow(person: filteredPeople[index]);
              },
            ),
          ),
        ],
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GiftListPage(person: person),
            ),
          );
        },
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
                displayMessage = 'Events on ${selectedDay.toLocal()}: ${events.join(', ')}';
              } else {
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

class GiftListPage extends StatefulWidget {
  final Map<String, dynamic> person;

  GiftListPage({required this.person});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  late List<String> giftList;
  final TextEditingController giftController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<String> filteredGiftList = [];

  @override
  void initState() {
    super.initState();
    giftList = List<String>.from(widget.person['gifts']);
    filteredGiftList = List<String>.from(giftList);
  }

  void _pledgeGift(String gift) {
    setState(() {
      giftList.add(gift);
      filteredGiftList = List<String>.from(giftList);  // Reset filtered list
    });
    giftController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pledged a gift: $gift')),
    );
  }

  void _searchGifts(String query) {
    setState(() {
      filteredGiftList = giftList
          .where((gift) => gift.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.person['name']}'s Gift List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: _searchGifts,
              decoration: InputDecoration(
                hintText: "Search for gifts",
                labelText: 'Search Gifts',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filteredGiftList.isEmpty
                ? Center(child: Text("No gifts found"))
                : ListView.builder(
              itemCount: filteredGiftList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredGiftList[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: giftController,
                    decoration: InputDecoration(
                      labelText: 'Gift Name',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (giftController.text.isNotEmpty) {
                      _pledgeGift(giftController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
