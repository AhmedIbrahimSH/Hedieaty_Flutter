import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsEventsPage extends StatefulWidget {
  final String userMail;
  FriendsEventsPage({required this.userMail});

  @override
  _FriendsEventsPageState createState() => _FriendsEventsPageState();
}

class _FriendsEventsPageState extends State<FriendsEventsPage> {
  late Stream<List<Event>> eventStream;
  String _sortOrder = 'Ascending'; // Default sorting is ascending

  @override
  void initState() {
    super.initState();
    eventStream = getEvents(widget.userMail);
  }

  // Function to get events from friends
  Stream<List<Event>> getEvents(String userMail) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('friendships')
        .snapshots()
        .asyncMap((friendshipsSnapshot) async {
      List<Event> events = [];
      for (var friendship in friendshipsSnapshot.docs) {
        var friendMail = friendship['mail'];
        var eventsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendMail)
            .collection('events')
            .get();

        for (var eventDoc in eventsSnapshot.docs) {
          var event = Event.fromFirestore(eventDoc);
          event.friendMail = friendMail;  // Store friendMail in the event object
          events.add(event);
        }
      }

      // Sort by date based on the selected sort order
      events.sort((a, b) {
        if (_sortOrder == 'Ascending') {
          return a.date.compareTo(b.date);
        } else {
          return b.date.compareTo(a.date);
        }
      });

      return events;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events of Friends'),
        actions: [
          // Dropdown to sort by date
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOrder = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Ascending', 'Descending'].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text('Sort by Date: $choice'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: eventStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No events found.'));
          }

          var events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(event.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${event.date}', style: TextStyle(color: Colors.grey[700])),
                      SizedBox(height: 4),
                      Text('Event by: ${event.friendMail}', style: TextStyle(color: Colors.grey[500])), // Display friendMail
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class Event {
  final String name;
  final String date;
  late String friendMail;  // Field to store the friend's email

  Event({required this.name, required this.date});

  factory Event.fromFirestore(DocumentSnapshot doc) {
    return Event(
      name: doc['name'],
      date: doc['date'],
    );
  }
}
