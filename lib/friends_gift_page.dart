import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FriendGiftsPage extends StatelessWidget {
  final String friendMail;
  final String current_logged_mail; // Example, replace with actual logged user email

  FriendGiftsPage({required this.current_logged_mail , required this.friendMail});

  Future<List<Map<String, dynamic>>> fetchFriendGifts() async {
    try {
      var eventsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendMail)
          .collection('events')
          .get();

      List<Map<String, dynamic>> gifts = [];

      for (var eventDoc in eventsSnapshot.docs) {
        var giftsSnapshot = await eventDoc.reference.collection('gifts').get();
        for (var giftDoc in giftsSnapshot.docs) {
          gifts.add(giftDoc.data() as Map<String, dynamic>);
        }
      }

      return gifts;
    } catch (e) {
      throw Exception("Error fetching gifts: $e");
    }
  }

  // Handle the pledge logic
  void _handlePledge(BuildContext context, String giftName) async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pledge Confirmation'),
          content: Text('Are you sure you want to pledge this gift?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed "No"
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed "Yes"
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (isConfirmed == true) {
      print("pledging : ${current_logged_mail} ${friendMail} ${giftName} ${context}");
      pledgeGift(current_logged_mail, friendMail, giftName, context);
    }
  }

  // Pledge gift logic
  void pledgeGift(String buyerMail, String receiverMail, String giftName, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'buyer': buyerMail,
        'pledgerer': receiverMail,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'pledge',
        'gift_name': giftName,
      });

      var usersCollection = FirebaseFirestore.instance.collection('users');
      var userDoc = await usersCollection.doc(receiverMail).get();
      print("User PLEDGED IS: ${userDoc.reference.path}"); // Path to the document
      if (userDoc.exists) {
        var eventsCollection = userDoc.reference.collection('events');
        var eventsSnapshot = await eventsCollection.get();
        for (var eventDoc in eventsSnapshot.docs) {
          var giftsCollection = eventDoc.reference.collection('gifts');
          var giftsSnapshot = await giftsCollection.where('gift_name', isEqualTo: giftName).get();

          if (giftsSnapshot.docs.isNotEmpty) {
            var giftDoc = giftsSnapshot.docs.first;

            await giftDoc.reference.update({'status': 'pledged'});

            await FirebaseFirestore.instance.collection('users')
                .doc(receiverMail)
                .collection('pledged_gifts')
                .add({
              'gift_owner': receiverMail,
              'gift_name': giftName,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gift pledged successfully!')),
            );

            return; // Exit after successful pledge
          }
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for $friendMail'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFriendGifts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No gifts found.'));
          }

          var gifts = snapshot.data!;

          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              var gift = gifts[index];
              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(gift['gift_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${gift['category']}'),
                      SizedBox(height: 4),
                      Text('Description: ${gift['description']}'),
                      SizedBox(height: 4),
                      Text('Owner: ${gift['gift_owner']}'),
                      SizedBox(height: 4),
                      Text('Link: ${gift['link']}'),
                      SizedBox(height: 4),
                      Text('Price: \$${gift['price']}'),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status: ${gift['status']}'),
                          if (gift['status'] == 'wanted')
                            ElevatedButton(
                              onPressed: () {
                                _handlePledge(context, gift['gift_name']);
                              },
                              child: Text('Pledge'),
                            ),
                        ],
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
