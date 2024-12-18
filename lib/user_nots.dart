import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final String currentmail;

  NotificationsPage({required this.currentmail});

  @override
  _NotificationsPageState createState() => _NotificationsPageState(currentmail: this.currentmail);
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Stream<QuerySnapshot> notificationsStream;
  String currentmail;
  _NotificationsPageState({required this.currentmail});

  @override
  void initState() {
    super.initState();
    notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
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
              String type = notification['type'];

              // For "friend_request" notifications
              if (type == 'frequest' && notification['receiver'] == this.currentmail) {
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
                          onPressed: () => rejectRequest( notification['sender'] , notification.id),
                          child: Text('Reject'),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => confirmDelete(notification.id, type),
                        ),
                      ],
                    )
                        : null,
                  ),
                );
              }

              // For "pledging" notifications
              if (type == 'pledge' && notification['pledgerer'] == this.currentmail) {
                String buyer = notification['buyer'];
                String pledger = notification['pledgerer'];
                String status = notification['status'];
                String gift_name = notification['gift_name'];

                // Update the status to 'seen' if it's not already 'seen'
                if (status != 'seen') {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notification.id)
                      .update({'status': 'seen'}).catchError((e) {
                    print('Error updating status to seen: $e');
                  });
                }

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    title: Text('$buyer promised to get you the gift: $gift_name'),
                    subtitle: Text('Buyer: $buyer\nStatus: $status'),
                    // trailing: IconButton(
                    //   icon: Icon(Icons.delete),
                    //   onPressed: () => confirmDelete(notification.id, type),
                    // ),
                  ),
                );
              }

              return SizedBox(); // Default return in case of unsupported notification type
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

      // Remove the friend request from both sender and receiver's friend request collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentmail)
          .collection('friend_request')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: widget.currentmail)
          .where('status', isEqualTo: 'sent')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderMail)
          .collection('friend_request')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: widget.currentmail)
          .where('status', isEqualTo: 'sent')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
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

  void rejectRequest(String senderMail , String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'rejected'});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderMail)
          .collection('friend_request')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: widget.currentmail)
          .where('status', isEqualTo: 'sent')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentmail)
          .collection('friend_request')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: widget.currentmail)
          .where('status', isEqualTo: 'sent')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request rejected.'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  // Confirm the deletion of notifications
  void confirmDelete(String notificationId, String type) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete all $type notifications?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                await deleteNotifications(type);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Notifications deleted.'),
                ));
              },
            ),
          ],
        );
      },
    );
  }

  // Delete all notifications based on type (receiver or pledgerer)
  Future<void> deleteNotifications(String type) async {
    try {
      QuerySnapshot snapshot;
      if (type == 'frequest') {
        snapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('receiver', isEqualTo: widget.currentmail)
            .get();
      } else if (type == 'pledge') {
        snapshot = await FirebaseFirestore.instance
            .collection('notifications')
            .where('pledgerer', isEqualTo: widget.currentmail)
            .get();
      } else {
        return;
      }

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting notifications: $e');
    }
  }
}
