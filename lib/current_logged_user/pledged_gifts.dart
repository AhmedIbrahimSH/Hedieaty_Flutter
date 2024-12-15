import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PledgedGiftsPage extends StatelessWidget {
  final String currentUserMail;

  PledgedGiftsPage({required this.currentUserMail});

  Future<List<Map<String, dynamic>>> fetchPledgedGifts() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserMail)
          .collection('pledged_gifts')
          .get();

      return snapshot.docs
          .map((doc) => {
        'due_date': doc['due_date'],
        'gift_name': doc['gift_name'],
        'gift_owner': doc['gift_owner'],
      })
          .toList();
    } catch (e) {
      throw Exception("Error fetching pledged gifts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pledged Gifts'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPledgedGifts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No pledged gifts found.'));
          }

          var gifts = snapshot.data!;

          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              var gift = gifts[index];

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    gift['gift_name'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date: ${gift['due_date']}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      Text(
                        'Owner: ${gift['gift_owner']}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.card_giftcard, color: Colors.teal),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
