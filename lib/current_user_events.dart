import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventListingPage extends StatefulWidget {
  final String currentUserMail;

  EventListingPage({required this.currentUserMail});

  @override
  _EventListingPageState createState() => _EventListingPageState();
}

class _EventListingPageState extends State<EventListingPage> {
  late Stream<QuerySnapshot> eventsStream;

  @override
  void initState() {
    super.initState();
    eventsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserMail)
        .collection('events')
        .snapshots();
  }

  // Delete event
  void deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('events')
          .doc(eventId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  // Edit event
  void editEvent(String eventId, String currentName) async {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Event Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Event Name'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.currentUserMail)
                      .collection('events')
                      .doc(eventId)
                      .update({'name': nameController.text});
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Event name cannot be empty!'),
                  ));
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

  // Add gift
  void addGift(String eventId) async {
    TextEditingController giftNameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Gift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: giftNameController,
                decoration: InputDecoration(labelText: 'Gift Name'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: linkController,
                decoration: InputDecoration(labelText: 'Link (Optional)'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                String giftName = giftNameController.text;
                String priceText = priceController.text;
                String? link = linkController.text.isNotEmpty ? linkController.text : null;

                if (giftName.isEmpty || priceText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gift name and price are required!'),
                  ));
                  return;
                }

                double? price = double.tryParse(priceText);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Price must be a valid number!'),
                  ));
                  return;
                }

                // Add gift to Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUserMail)
                    .collection('events')
                    .doc(eventId)
                    .collection('gifts')
                    .add({
                  'name': giftName,
                  'owner': widget.currentUserMail,
                  'price': price,
                  'link': link,
                  'status': 'wanted',
                });

                Navigator.pop(context);
              },
              child: Text('Save Gift'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No events found.'));
          }

          var events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              String eventId = event.id;
              String eventName = event['name'];
              DateTime eventDate = (event['date'] as Timestamp).toDate();

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(eventName),
                  subtitle: Text('Date: ${eventDate.toString()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle),
                        onPressed: () => addGift(eventId),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => editEvent(eventId, eventName),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteEvent(eventId),
                      ),
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
