import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  final String currentUserMail;

  EventsPage({required this.currentUserMail});

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    // Stream to get all events for the current user, sorted by date in descending order
    _eventsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserMail)
        .collection('events')
        .orderBy('date', descending: true) // Order by date in descending order
        .snapshots();
  }

  // Function to delete an upcoming event
  Future<void> deleteEvent(String eventId) async {
    // Show confirmation dialog before deleting
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event'),
          content: Text('Are you sure you want to delete this event?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false to cancel
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true to confirm
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    // If the user confirms deletion, proceed with deleting the event
    if (confirmDelete ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserMail)
            .collection('events')
            .doc(eventId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event deleted successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print("Error deleting event: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String formatDate(String date) {
    try {
      // Parse the string into a DateTime object (assuming the string format is 'yyyy-MM-dd')
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate); // Format to 'dd/MM/yyyy'
    } catch (e) {
      // If parsing fails, return a placeholder or an error message
      print('Invalid date format: $date');
      return 'Invalid date';
    }
  }

  // Function to determine if an event is upcoming
  bool isUpcoming(String eventDate) {
    try {
      // Parse the string date into a DateTime object
      DateTime eventDateTime = DateTime.parse(eventDate);
      return eventDateTime.isAfter(DateTime.now()); // Check if the event date is after the current date
    } catch (e) {
      print('Invalid date format: $eventDate');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No events found!',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Get the events from the snapshot
          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventName = event['name'];
              final eventDate = event['date']; // Ensure this is a valid string
              final eventId = event.id;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(eventName, style: TextStyle(fontSize: 18)),
                  subtitle: Text(
                    'Date: ${eventDate}', // Now passing the string directly
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: isUpcoming(eventDate)
                      ? IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      deleteEvent(eventId);
                    },
                  )
                      : null, // No delete option for past events
                ),
              );
            },
          );
        },
      ),
    );
  }
}
