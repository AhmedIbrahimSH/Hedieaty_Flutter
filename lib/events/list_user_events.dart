import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:app/local_database/local_sql_init.dart';

import '../gift_list_per_event.dart';


class EventsPage extends StatefulWidget {
  final String currentUserMail;
  LocalDatabase localdb;
  EventsPage({required this.currentUserMail, required this.localdb});

  @override
  _EventsPageState createState() => _EventsPageState(localdb:this.localdb);
}

class _EventsPageState extends State<EventsPage> {
  late Stream<QuerySnapshot> _eventsStream;
  LocalDatabase localdb;
  bool isButtonVisible = true;
  bool isButtonPressed = false;
  String sortBy = 'Name';
  String statusFilter = 'Upcoming';

  _EventsPageState({required this.localdb});
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


  Future<void> addGift(String eventName) async {
    TextEditingController giftNameController = TextEditingController();
    TextEditingController giftPriceController = TextEditingController();
    TextEditingController giftLinkController = TextEditingController();
    String? selectedCategory = 'Electronics';

    XFile? pickedImage;
    final ImagePicker _picker = ImagePicker();

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
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
                items: <String>['Electronics', 'Books', 'Clothes', 'Toys', 'Accessories', 'Custom']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                      setState(() {});
                    },
                    child: Text('Pick Image'),
                  ),
                  SizedBox(width: 10),
                  if (pickedImage != null)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: FileImage(File(pickedImage!.path)),
                    ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                String giftName = giftNameController.text;
                String giftPrice = giftPriceController.text;
                String giftLink = giftLinkController.text;

                // Validation for required fields
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

                // Prepare image path if there is one
                String imagePath = '';
                if (pickedImage != null) {
                  imagePath = pickedImage!.path;
                }

                try {
                  // Insert the gift into local database
                  await this.localdb.insertGiftLocally(
                    eventName,
                    giftName,
                    price,
                    giftLink,
                    selectedCategory.toString(),
                    imagePath,
                    widget.currentUserMail,
                  );

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
      return eventDateOnly.isAtSameMomentAs(now) || eventDateOnly.isAfter(now);
    } catch (e) {
      print('Invalid date format: $eventDate');
      return false;
    }
  }

  List<Map<String, dynamic>> _filterEventsByStatus(List<Map<String, dynamic>> events) {
    // Example: Filter logic for upcoming events (modify as needed)
    return events.where((event) {
      final eventDate = DateTime.parse(event['date']);
      return eventDate.isAfter(DateTime.now());
    }).toList();
  }


  void _updateStream() {
    setState(() {
      if (sortBy == 'Name') {
        _eventsStream = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserMail)
            .collection('events')
            .orderBy('name')
            .snapshots();
      } else if (sortBy == 'Date') {
        _eventsStream = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserMail)
            .collection('events')
            .orderBy('date', descending: true)
            .snapshots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Events'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: sortBy,
                onChanged: (newValue) {
                  setState(() {
                    sortBy = newValue!;
                    _updateStream();
                  });
                },
                items: <String>['Name', 'Date']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(width: 20),
              DropdownButton<String>(
                value: statusFilter,
                onChanged: (newValue) {
                  setState(() {
                    statusFilter = newValue!;
                  });
                },
                items: <String>['Upcoming', 'Present', 'Past']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: localdb.getLocalEvents(widget.currentUserMail), // Use your function here
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No events found!',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final events = snapshot.data!;
                final filteredEvents = _filterEventsByStatus(events.map((e) {
                  return {
                    'name': e['name'],
                    'date': e['date'],
                  };
                }).toList());

                return Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      children: filteredEvents.map((event) {
                        final eventName = event['name'];
                        final eventDate = event['date'];
                        final eventId = event['name'];

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListTile(
                              onTap: (){
                                // here gpt
                              },
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
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GiftsPage(
                                            eventId: eventId,
                                            eventName: eventName,
                                            currentUserMail: widget.currentUserMail,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (isUpcoming(eventDate))
                                    AnimatedOpacity(
                                      opacity: isButtonVisible ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 500),
                                      child: IconButton(
                                        icon: Icon(Icons.add_card),
                                        onPressed: () {
                                          addGift(eventName);
                                        },
                                      ),
                                    ),
                                  if (isUpcoming(eventDate))
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await localdb.deleteEvent(
                                            mail: widget.currentUserMail,
                                            eventName: eventName);
                                      },
                                    ),
                                  FutureBuilder<bool>(
                                    future: this.localdb.isEventInFirebase(
                                        widget.currentUserMail, eventName),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasData &&
                                          snapshot.data == false &&
                                          !isButtonPressed) {
                                        return AnimatedOpacity(
                                          opacity: isButtonVisible ? 1.0 : 0.0,
                                          duration: Duration(milliseconds: 500),
                                          child: IconButton(
                                            icon: Icon(Icons.cloud_upload),
                                            onPressed: () async {
                                              await this.localdb.insertEventToFirebase(
                                                  widget.currentUserMail,
                                                  eventName,
                                                  eventDate);
                                              setState(() {
                                                isButtonPressed = true;
                                              });
                                            },
                                          ),
                                        );
                                      } else {
                                        return Container();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}

