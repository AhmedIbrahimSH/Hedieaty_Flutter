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
    _eventsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserMail)
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> deleteEvent(String eventId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Event'),
          content: Text('Are you sure you want to delete this event?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

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

  Future<void> addGift(String eventId) async {
    TextEditingController giftNameController = TextEditingController();
    TextEditingController giftPriceController = TextEditingController();
    TextEditingController giftLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add a Gift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: giftNameController,
                decoration: InputDecoration(labelText: 'Gift Name'),
              ),
              TextField(
                controller: giftPriceController,
                decoration: InputDecoration(labelText: 'Gift Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: giftLinkController,
                decoration: InputDecoration(labelText: 'Link (optional)'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                String giftName = giftNameController.text;
                String giftPrice = giftPriceController.text;
                String giftLink = giftLinkController.text;

                if (giftName.isEmpty || giftPrice.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gift name and price are required!')),
                  );
                  return;
                }

                double? price = double.tryParse(giftPrice);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price!')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserMail)
                      .collection('events')
                      .doc(eventId)
                      .collection('gifts')
                      .add({
                    'gift_name': giftName,
                    'price': price,
                    'link': giftLink,
                    'status': 'wanted',
                    'gift_owner': widget.currentUserMail,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gift added successfully!')),
                  );
                } catch (e) {
                  print("Error adding gift: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add gift.')),
                  );
                }
              },
              child: Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      print('Invalid date format: $date');
      return 'Invalid date';
    }
  }

  bool isUpcoming(String eventDate) {
    try {
      DateTime eventDateTime = DateTime.parse(eventDate);

      DateTime now = DateTime.now();
      DateTime eventDateOnly = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
      print("printed before ${eventDateOnly}");
      print("after ${DateTime(now.year, now.month, now.day)}");
      return eventDateOnly.isAtSameMomentAs(now) || eventDateOnly.isAfter(now);
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

          final events = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Column(
              children: events.map((event) {
                final eventName = event['name'];
                final eventDate = event['date'];
                final eventId = event.id;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListTile(
                      title: Text(
                        eventName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Date: ${formatDate(eventDate)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUpcoming(eventDate))
                            IconButton(
                              icon: Icon(Icons.add_card),
                              onPressed: () {
                                addGift(eventId);
                              },
                            ),
                          if (isUpcoming(eventDate))
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                deleteEvent(eventId);
                              },
                            ),
                        ],
                      ),

                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
