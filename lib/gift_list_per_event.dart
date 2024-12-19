import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GiftsPage extends StatefulWidget {
  final String currentUserMail;
  final String eventId;
  final String eventName;
  const GiftsPage({Key? key, required this.currentUserMail, required this.eventId, required this.eventName}) : super(key: key);

  @override
  _GiftsPageState createState() => _GiftsPageState(eventName:this.eventName);
}

class _GiftsPageState extends State<GiftsPage> {
  List<Map<String, dynamic>> localGifts = [];
  List<String> firebaseGiftNames = [];
  final String eventName;
  _GiftsPageState({required this.eventName});
  @override
  void initState() {
    super.initState();
    fetchLocalGifts(this.eventName);
    fetchFirebaseGifts();
  }

  Future<void> fetchLocalGifts(eventName) async {
    final dbPath = await getDatabasesPath();
    final database = await openDatabase(join(dbPath, 'local_db.db'));

    final List<Map<String, dynamic>> result = await database.query(
      'gifts',
      where: 'event_name = ?',
      whereArgs: [widget.eventId],
    );

    setState(() {
      localGifts = result;
    });
  }

  Future<void> fetchFirebaseGifts() async {
    print("event is ${eventName} ${widget.currentUserMail}");
    try {
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('events')
          .where('name', isEqualTo: eventName)
          .limit(1)
          .get();

      if (eventSnapshot.docs.isNotEmpty) {
        var eventDoc = eventSnapshot.docs.first;
        QuerySnapshot giftsSnapshot = await eventDoc.reference
            .collection('gifts')
            .get();

        List<String> giftNames = [];
        for (var giftDoc in giftsSnapshot.docs) {
          String giftName = giftDoc['gift_name'];
          giftNames.add(giftName);
        }

        setState(() {
          firebaseGiftNames = giftNames;
        });

        print(firebaseGiftNames);
      } else {
        print("Event not found");
      }
    } catch (e) {
      print("Error fetching Firebase gifts: $e");
    }
  }



  Future<void> addGiftByEventName(String eventName, Map<String, dynamic> giftData) async {
    try {
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('events')
          .where('name', isEqualTo: eventName)
          .get();

      if (eventSnapshot.docs.isEmpty) {
        print("Event with name '$eventName' not found.");
        return;
      }

      String eventId = eventSnapshot.docs.first.id;
      print("Found Event ID: $eventId");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('events')
          .doc(eventId)
          .collection('gifts')
          .add(giftData);

      print("Gift added successfully to event: $eventName");
    } catch (e) {
      print("Error adding gift by event name: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for Event ${widget.eventId}'),
      ),
      body: ListView.builder(
        itemCount: localGifts.length,
        itemBuilder: (context, index) {
          final gift = localGifts[index];
          print("${firebaseGiftNames} ${gift['gift_name']}");
          bool existsInFirebase = firebaseGiftNames.contains(gift['gift_name']);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
            child: ListTile(
              title: Text(
                gift['gift_name'],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Price: \$${gift['price']} \nStatus: ${gift['status']}'),
              trailing: existsInFirebase
                  ? Icon(Icons.cloud_done, color: Colors.green)
                  : IconButton(
                icon: Icon(Icons.cloud_upload, color: Colors.blue),
                onPressed: () {addGiftByEventName(eventName, gift);setState(() {
                      fetchFirebaseGifts();
                });},
              ),
            ),
          );
        },
      ),
    );
  }
}
