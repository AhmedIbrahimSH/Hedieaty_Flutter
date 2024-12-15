import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftsPage extends StatefulWidget {
  final String userMail;
  GiftsPage({required this.userMail});

  @override
  _GiftsPageState createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  late Stream<List<Gift>> giftStream;

  @override
  void initState() {
    super.initState();
    giftStream = getGifts(widget.userMail);
  }

  // Function to get gifts
  Stream<List<Gift>> getGifts(String userMail) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userMail)
        .collection('gifts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Gift.fromFirestore(doc)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts'),
      ),
      body: StreamBuilder<List<Gift>>(
        stream: giftStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No gifts found.'));
          }

          var gifts = snapshot.data!;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              var gift = gifts[index];
              return ListTile(
                title: Text(gift.category),
                subtitle: Text('Event: ${gift.event}\nStatus: ${gift.status}'),
              );
            },
          );
        },
      ),
    );
  }
}

class Gift {
  final String category;
  final String event;
  final String status;

  Gift({required this.category, required this.event, required this.status});

  factory Gift.fromFirestore(DocumentSnapshot doc) {
    return Gift(
      category: doc['category'],
      event: doc['event'],
      status: doc['status'],
    );
  }
}
