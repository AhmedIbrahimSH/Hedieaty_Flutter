import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gift_details.dart';
import 'package:intl/intl.dart';

class FriendsEventPage extends StatefulWidget {
  final String userMail;
  final String current_logged_mail;

  const FriendsEventPage({Key? key, required this.current_logged_mail ,  required this.userMail}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState(current_logged_mail: this.current_logged_mail , usermail: this.userMail);
}

class _EventPageState extends State<FriendsEventPage> {
  late Future<Map<DateTime, List<Map<String, dynamic>>>> _eventsFuture;
  final String current_logged_mail;
  String usermail;
  _EventPageState({required this.current_logged_mail , required this.usermail});
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
        DateTime normalizedEventDate = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (!eventsByDate.containsKey(normalizedEventDate)) {
          eventsByDate[normalizedEventDate] = [];
        }

        eventsByDate[normalizedEventDate]!.add({
          ...eventData,
          'id': doc.id,
        });
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

  Future<List<Map<String, dynamic>>> fetchGifts(String eventId) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userMail)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }
    print("ff ${snapshot.docs.map((doc) => doc.data()).toList()}");
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Widget _buildGiftList(String eventId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchGifts(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No gifts available.'));
        }

        final gifts = snapshot.data!;
        return Column(
          children: gifts.map((gift) {

            return _GiftTile(gift: gift, current_logged_mail: this.current_logged_mail, event_date: DateFormat('yyyy-MM-dd').format(_selectedDay!) , usermail: this.usermail,);
          }).toList(),
        );
      },
    );
  }

  List<Widget> _buildEventList(DateTime day, Map<DateTime, List<Map<String, dynamic>>> events) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    final dayEvents = events[normalizedDay] ?? [];
    print("FF ${dayEvents}");
    return dayEvents.map((event) {
      return ExpansionTile(
        title: Text(event['name'] ?? 'Unnamed Event'),
        subtitle: Text('Date: ${event['date']}'),
        children: [
          _buildGiftList(event['id']),
        ],
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


class _GiftTile extends StatefulWidget {
  final Map<String, dynamic> gift;
  final String current_logged_mail;
  final String event_date;
  final String usermail;

  const _GiftTile({
    Key? key,
    required this.current_logged_mail,
    required this.gift,
    required this.event_date,
    required this.usermail,
  }) : super(key: key);

  @override
  __GiftTileState createState() => __GiftTileState(
    current_logged_mail: this.current_logged_mail,
    event_date: this.event_date,
    usermail: this.usermail,
  );
}

class __GiftTileState extends State<_GiftTile> {
  bool isPledged = false;
  final String current_logged_mail;
  final String event_date;
  String usermail;
  String? eventId;
  String? giftId;

  __GiftTileState({
    required this.current_logged_mail,
    required this.event_date,
    required this.usermail,
  });
  @override
  void initState() {
    super.initState();
    _fetchEventAndGiftId();
  }

  Future<void> _fetchEventAndGiftId() async {
    try {
      print("man is ${widget.usermail}");
      eventId = await getEventIdForSelectedDay(event_date as String, widget.usermail);
      print("event id man is ${eventId}");
      if (eventId != null) {
        giftId = await getGiftIdForEvent(eventId!, widget.gift['gift_name']);
        setState(() {});
      }
    } catch (e) {
      print('Error fetching IDs: $e');
    }
  }

  Future<String?> getEventIdForSelectedDay(String _selectedDay, String currentLoggedMail) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentLoggedMail)
          .collection('events')
          .where('date', isEqualTo: _selectedDay)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String eventId = querySnapshot.docs.first.id;
        print('Found event with ID: $eventId');
        return eventId;
      } else {
        print('No event found for the selected day $_selectedDay');
      }
    } catch (e) {
      print('Error while searching for event: $e');
    }
    return null;
  }

  Future<String?> getGiftIdForEvent(String eventId, String giftName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usermail)
          .collection('events')
          .doc(eventId)
          .collection('gifts')
          .where('gift_name', isEqualTo: giftName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        String giftId = querySnapshot.docs.first.id;
        print('Found gift with ID: $giftId');
        return giftId;
      } else {
        print('No gift found with name $giftName in event $eventId');
      }
    } catch (e) {
      print('Error while searching for gift: $e');
    }
    return null;
  }
  void pledgeGift(String buyerMail, String receiverMail, String gift_name) async {
    try {
      // Add the pledge to the 'notifications' collection
      await FirebaseFirestore.instance.collection('notifications').add({
        'buyer': buyerMail,
        'pledgerer': receiverMail,
        'status': 'pending',  // Assuming this status means unread
        'timestamp': FieldValue.serverTimestamp(),  // For sorting notifications by time
        'type': 'pledge',
        'gift_name': gift_name,
      });

      var usersCollection = FirebaseFirestore.instance.collection('users');
      var userDoc = await usersCollection.doc(buyerMail).get();

      if (userDoc.exists) {
        print("User document found");

        var eventsCollection = userDoc.reference.collection('events');
        var eventsSnapshot = await eventsCollection.get();

        for (var eventDoc in eventsSnapshot.docs) {
          print("Found event: ${eventDoc.id}");

          var giftsCollection = eventDoc.reference.collection('gifts');

          var giftsSnapshot = await giftsCollection.where('gift_name', isEqualTo: widget.gift['gift_name']).get();

          if (giftsSnapshot.docs.isNotEmpty) {
            var giftDoc = giftsSnapshot.docs.first;
            print("Gift found: ${giftDoc.data()}");

            await giftDoc.reference.update({
              'status': 'pledged',
            });

            await FirebaseFirestore.instance.collection('users')
                .doc(current_logged_mail)
                .collection('pledged_gifts')
                .add({
              'gift_owner': current_logged_mail,
              'gift_name': widget.gift['gift_name'],
              'due_date': event_date,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gift pledged successfully!')),
            );

            return;
          } else {
            print("No gift found for ${widget.gift['gift_name']} in this event");
          }
        }
      } else {
        print("User document not found");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift not found!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pledging gift: $e')),
      );
    }
  }

  void _handlePledge() async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pledge Confirmation'),
          content: Text('Are you sure you want to pledge this gift?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
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

    if (isConfirmed == true) {
      setState(() {
        isPledged = true;
      });

      pledgeGift(usermail, current_logged_mail, widget.gift['gift_name']);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You have pledged the gift: ${widget.gift['gift_name']}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Current logged email: ${widget.current_logged_mail}');
    print('Event date: ${widget.event_date}');
    print('Gift name: ${widget.gift['gift_name']}');
    if (eventId == null || giftId == null) {
      return Center(child: CircularProgressIndicator());
    }
    FirebaseFirestore.instance
        .collection('users')
        .doc(current_logged_mail)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .get()
        .then((doc) {
      if (doc.exists) {
        print('Document exists');
      } else {
        print('Document does not exist');
      }
    });

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.usermail)
          .collection('events')
          .doc(eventId! as String)
          .collection('gifts')
          .doc(giftId! as String)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Text('Gift not found');
        }

        var giftData = snapshot.data!.data() as Map<String, dynamic>?;

        if (giftData == null) {
          return Text('Gift data is null');
        }

        IconData giftIcon = giftData['status'] == 'pledged'
            ? Icons.check_circle
            : Icons.card_giftcard;

        Color iconColor = giftData['status'] == 'wanted'
            ? Colors.green
            : Colors.blue;

        return ListTile(
          leading: CircleAvatar(
              backgroundImage:
              NetworkImage('https://cdn.pixabay.com/photo/2019/10/22/03/34/gift-4567561_640.jpg')

          ),
          title: Text(widget.gift['gift_name'] ?? 'Unnamed Gift'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${widget.gift['category'] ?? 'No Category'}'),
              Text('Price: \$${widget.gift['price']}'),
              Text('Status: ${giftData['status']}'),
              Text('Link:'),
              GestureDetector(
                onTap: () async {
                  final url = widget.gift['link'];
                  if (url != null && await canLaunch(url)) {
                    bool? openLink = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('External Link'),
                          content: Text(
                              'You will leave the app to open an external link. Do you want to continue?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              child: Text('No'),
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

                    if (openLink == true) {
                      await launch(url);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Invalid or missing URL'),
                    ));
                  }
                },
                child: Text(
                  widget.gift['link'] ?? 'No link available',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              giftIcon,
              color: iconColor,
            ),
            onPressed: () {
              if (widget.gift['status'] == 'wanted') {
                _handlePledge();
              }
            },
          ),
        );
      },
    );
  }}