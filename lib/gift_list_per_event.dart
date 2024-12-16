import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftsPage extends StatelessWidget {
  final String currentUserMail;
  final String eventId;

  const GiftsPage({Key? key, required this.currentUserMail, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserMail)
            .collection('events')
            .doc(eventId)
            .collection('gifts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No gifts found!'));
          }

          return ListView(
            padding: EdgeInsets.all(8.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> gift = document.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16.0),
                  title: Text(
                    gift['gift_name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: \$${gift['price']}'),
                      SizedBox(height: 4),
                      Text('Status: ${gift['status']}'),
                    ],
                  ),
                  trailing: gift['status'] == 'wanted'
                      ? IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Delete gift from Firebase
                      document.reference.delete();
                    },
                  )
                      : Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
