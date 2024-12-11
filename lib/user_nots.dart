import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final String currentmail;

  NotificationsPage({required this.currentmail});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Stream<QuerySnapshot> notificationsStream;

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('receiver', isEqualTo: widget.currentmail)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No notifications.'));
          }

          var notifications = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];
              String sender = notification['sender'];
              String status = notification['status'];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10.0),
                  title: Text('Friend request from $sender'),
                  subtitle: Text('Status: $status'),
                  trailing: status == 'pending'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => acceptRequest(notification.id, sender),
                        child: Text('Accept'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => rejectRequest(notification.id),
                        child: Text('Reject'),
                      ),
                    ],
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Accept the friend request
  void acceptRequest(String notificationId, String senderMail) async {
    try {
      // Update the notification status to 'accepted'
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'accepted'});

      // Add the friend in both users' friend lists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderMail)
          .collection('friendships')
          .doc(widget.currentmail)
          .set({'mail': widget.currentmail});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentmail)
          .collection('friendships')
          .doc(senderMail)
          .set({'mail': senderMail});

      // Send notification to sender
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': widget.currentmail,
        'receiver': senderMail,
        'status': 'accepted',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$senderMail has accepted your friend request!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  // Reject the friend request (delete notification)
  void rejectRequest(String notificationId) async {
    try {
      // Delete the notification from Firestore
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request rejected.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }
}
