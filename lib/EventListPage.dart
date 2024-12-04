import 'package:flutter/material.dart';

class EventListPage extends StatefulWidget {
  final List<Map<String, dynamic>> people;

  const EventListPage({Key? key, required this.people}) : super(key: key);

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> filteredEvents = [];

  String _sortBy = 'name';
  bool _isAscending = true;
  String _eventStatus = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _extractAllEvents();
    _filterEvents();
  }

  void _extractAllEvents() {
    allEvents.clear();
    for (var person in widget.people) {
      person['events'].forEach((date, eventList) {
        for (var eventName in eventList) {
          allEvents.add({
            'name': person['name'],
            'eventName': eventName,
            'date': date,
            'avatar': person['avatar'],
          });
        }
      });
    }
  }

  void _filterEvents() {
    setState(() {
      var tempEvents = allEvents.where((event) {
        final nameMatch = event['name'].toLowerCase().contains(_searchController.text.toLowerCase());
        final eventNameMatch = event['eventName'].toLowerCase().contains(_searchController.text.toLowerCase());
        return nameMatch || eventNameMatch;
      }).toList();

      tempEvents = tempEvents.where((event) {
        final eventDate = event['date'] as DateTime;
        final now = DateTime.now();

        switch (_eventStatus) {
          case 'Upcoming':
            return eventDate.isAfter(now);
          case 'Past':
            return eventDate.isBefore(now);
          case 'Current':
            return eventDate.year == now.year &&
                eventDate.month == now.month &&
                eventDate.day == now.day;
          default:
            return true;
        }
      }).toList();

      // Sort events
      tempEvents.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a['name'].compareTo(b['name']);
            break;
          case 'date':
            comparison = (a['date'] as DateTime).compareTo(b['date'] as DateTime);
            break;
          case 'eventName':
            comparison = a['eventName'].compareTo(b['eventName']);
            break;
          default:
            comparison = 0;
        }
        return _isAscending ? comparison : -comparison;
      });

      filteredEvents = tempEvents;
    });
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    final nameController = TextEditingController(text: event['eventName']);
    final dateController = TextEditingController(
        text: '${event['date'].year}-${event['date'].month}-${event['date'].day}'
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Event Name'),
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Event updated (placeholder)')),
                );
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    String? selectedPerson;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    hint: Text('Select Person'),
                    value: selectedPerson,
                    items: widget.people.map((person) {
                      return DropdownMenuItem(
                        value: person['name'] as String,
                        child: Text(person['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPerson = value;
                      });
                    },
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Event Name'),
                  ),
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    keyboardType: TextInputType.datetime,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedPerson != null &&
                        nameController.text.isNotEmpty &&
                        dateController.text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Event added (placeholder)')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterEvents(),
              decoration: InputDecoration(
                labelText: 'Search Events',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    hint: Text('Sort By'),
                    items: [
                      DropdownMenuItem(value: 'name', child: Text('Name')),
                      DropdownMenuItem(value: 'date', child: Text('Date')),
                      DropdownMenuItem(value: 'eventName', child: Text('Event Name')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                        _filterEvents();
                      });
                    },
                  ),
                ),

                IconButton(
                  icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _isAscending = !_isAscending;
                      _filterEvents();
                    });
                  },
                ),

                Expanded(
                  child: DropdownButton<String>(
                    value: _eventStatus,
                    hint: Text('Status'),
                    items: [
                      DropdownMenuItem(value: 'All', child: Text('All Events')),
                      DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
                      DropdownMenuItem(value: 'Current', child: Text('Current')),
                      DropdownMenuItem(value: 'Past', child: Text('Past')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _eventStatus = value!;
                        _filterEvents();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredEvents.isEmpty
                ? Center(child: Text('No events found'))
                : ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(event['avatar']),
                  ),
                  title: Text(event['eventName']),
                  subtitle: Text('${event['name']} - ${event['date'].toString()}'),

                );
              },
            ),
          ),
        ],
      ),
    );
  }
}