import 'package:flutter/material.dart';

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
  // List to hold the data for the rows
  List<Map<String, dynamic>> people = [
    {'name': 'John Doe', 'avatar': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'Jane Smith', 'avatar': 'https://i.pravatar.cc/150?img=2'},
    {'name': 'Michael Lee', 'avatar': 'https://i.pravatar.cc/150?img=3'},
    {'name': 'Emily Davis', 'avatar': 'https://i.pravatar.cc/150?img=4'},
  ];

  // List to hold events that can be added to each row
  List<Map<String, dynamic>> events = [];

  // Function to add a new event
  void _addEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return EventDialog(
          onSubmit: (eventName, itemsList) {
            setState(() {
              events.add({
                'name': eventName,
                'items': itemsList,
              });
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event List')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEvent(context),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          return EventRow(
            person: people[index],
            events: events,
            onEventPressed: (event) {
              // Show the event details when the right button is clicked
              showDialog(
                context: context,
                builder: (context) {
                  return EventDetailsDialog(event: event);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EventDialog extends StatefulWidget {
  final Function(String, List<String>) onSubmit;

  EventDialog({required this.onSubmit});

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _itemsController = TextEditingController();

  // To store items as bullet points
  List<String> _items = [];

  // Function to add a bullet point item
  void _addItem() {
    if (_itemsController.text.isNotEmpty) {
      setState(() {
        _items.add(_itemsController.text);
        _itemsController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _eventNameController,
            decoration: InputDecoration(labelText: 'Event Name'),
          ),
          TextField(
            controller: _itemsController,
            decoration: InputDecoration(labelText: 'Item (Bullet Point)'),
            onSubmitted: (_) => _addItem(),
          ),
          ElevatedButton(
            onPressed: _addItem,
            child: Text('Add Item'),
          ),
          SizedBox(height: 10),
          Text('Items:'),
          for (var item in _items)
            Text(
              '• $item',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_eventNameController.text.isNotEmpty && _items.isNotEmpty) {
              widget.onSubmit(_eventNameController.text, _items);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class EventRow extends StatelessWidget {
  final Map<String, dynamic> person;
  final List<Map<String, dynamic>> events;
  final Function(Map<String, dynamic>) onEventPressed;

  EventRow({required this.person, required this.events, required this.onEventPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(person['avatar']),
        ),
        title: Text(person['name']),
        trailing: ElevatedButton(
          onPressed: () {
            // Open a dialog to display the event details
            if (events.isNotEmpty) {
              onEventPressed(events.last);  // Show the latest added event
            }
          },
          child: Text(events.isNotEmpty ? 'Show Event' : 'No Event'),
        ),
      ),
    );
  }
}

class EventDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> event;

  EventDetailsDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event['name']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Items:'),
          for (var item in event['items'])
            Text(
              '• $item',
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}
