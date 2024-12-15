import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatelessWidget {
  final String currentmail;

  UsersPage({required this.currentmail});

  // Fetch all users method
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> allUsers = snapshot.docs
          .map((doc) => {
        ...doc.data(),
        'id': doc.id  // Include document ID for guaranteed unique identification
      })
          .toList();

      print("Total users fetched: ${allUsers.length}");
      allUsers.forEach((user) {
        print("User details: ${user['name']} - ${user['mail']}");
      });

      return allUsers;
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Fetch current user's friends
  Future<List<String>> fetchUserFriends() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentmail)
          .collection('friendships')
          .get();

      List<String> friends = snapshot.docs.map((doc) => doc['mail'] as String).toList();

      print('Total friends count: ${friends.length}');
      friends.forEach((friend) {
        print("Friend: $friend");
      });

      return friends;
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          var allUsers = snapshot.data!;

          return FutureBuilder<List<String>>(
            future: fetchUserFriends(),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (friendSnapshot.hasError) {
                return Center(child: Text('Error fetching friends: ${friendSnapshot.error}'));
              }

              List<String> friends = friendSnapshot.data ?? [];

              var filteredUsers = allUsers.where((user) {
                String userMail = user['mail'];
                return userMail != currentmail && !friends.contains(userMail);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(child: Text('No users available to add.'));
              }

              return ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10.0),
                      title: Text(filteredUsers[index]['name'] ?? 'Unknown'),
                      subtitle: Text(filteredUsers[index]['mail'] ?? 'Unknown Mail'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          addFriend(context, filteredUsers[index]['mail']);
                        },
                        child: Text('Add Friend'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void addFriend(BuildContext context, String userMail) async {
    try {
      // Create a notification for the receiver that there's a pending friend request
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': currentmail,
        'receiver': userMail,
        'status': 'pending', // 'pending' until the receiver accepts
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'frequest'
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request sent to $userMail!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }


  // Accept a friend request
  void acceptFriendRequest(BuildContext context, String senderMail) async {
    try {
      // Add friendships for both users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentmail)
          .collection('friendships')
          .doc(senderMail)
          .set({'mail': senderMail});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderMail)
          .collection('friendships')
          .doc(currentmail)
          .set({'mail': currentmail});

      // Update notification status to accepted
      var notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: currentmail)
          .get();

      notificationSnapshot.docs.forEach((doc) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'status': 'accepted'});
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request accepted from $senderMail'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  // Reject a friend request
  void rejectFriendRequest(BuildContext context, String senderMail) async {
    try {
      // Delete the notification if rejected
      var notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('sender', isEqualTo: senderMail)
          .where('receiver', isEqualTo: currentmail)
          .get();

      notificationSnapshot.docs.forEach((doc) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .delete();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Friend request rejected from $senderMail'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }
}
