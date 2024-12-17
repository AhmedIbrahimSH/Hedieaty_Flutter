import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsersPage extends StatefulWidget {
  final String currentmail;

  UsersPage({required this.currentmail});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allUsers = [];

  @override
  void initState() {
    super.initState();
    fetchAllUsers(); // Fetch all users initially
  }

  Future<void> fetchAllUsers() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        allUsers = snapshot.docs
            .map((doc) => {
          ...doc.data(),
          'id': doc.id, // Include document ID for guaranteed unique identification
        })
            .toList();
      });

      print("Total users fetched: ${allUsers.length}");
    } catch (e) {
      print('Error fetching all users: $e');
    }
  }

  void updateFriendRequest(String currentMail, String otherMail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    Map<String, dynamic> friendRequest = {
      'sender': currentMail,
      'receiver': otherMail,
      'status': 'sent',
    };

    try {
      DocumentReference currentUserRef = firestore.collection('users').doc(currentMail);

      await currentUserRef.collection('friend_request').add(friendRequest);

      DocumentReference receiverUserRef = firestore.collection('users').doc(otherMail);
      await receiverUserRef.collection('friend_request').add({
        'sender': currentMail,
        'receiver': otherMail,
        'status': 'sent',  // Status for the receiver is 'pending'
      });


      print('Friend request sent from $currentMail to $otherMail');
    } catch (e) {
      print('Error updating friend request: $e');
    }
  }

  // Check if a friend request exists
  Future<bool> hasRequestSent(String currentMail, String friendMail) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentMail)
          .collection('friend_request')
          .where('sender', isEqualTo: currentMail)
          .where('receiver', isEqualTo: friendMail)
          .where('status', isEqualTo: 'sent')
          .get();
      var ssnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendMail)
          .collection('friend_request')
          .where('sender', isEqualTo: friendMail)
          .where('receiver', isEqualTo: currentMail)
          .where('status', isEqualTo: 'sent')
          .get();

      return snapshot.docs.isNotEmpty || ssnapshot.docs.isNotEmpty; // If a matching document is found, return true
    } catch (e) {
      print('Error checking friend request status: $e');
      return false;
    }
  }

  // Fetch current user's friends
  Future<List<String>> fetchUserFriends() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentmail)
          .collection('friendships')
          .get();

      List<String> friends = snapshot.docs.map((doc) => doc['mail'] as String).toList();

      print('Total friends count: ${friends.length}');
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by Phone Number',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {});
              },
            ),
          ),
          FutureBuilder<List<String>>(
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
                String userPhone = user['phone'] ?? '';
                String query = searchController.text.toLowerCase();

                // Filter to exclude current user and existing friends
                return userMail != widget.currentmail &&
                    !friends.contains(userMail) &&
                    userPhone.contains(query);
              }).toList();

              if (filteredUsers.isEmpty) {
                return Center(child: Text('No users available to add.'));
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<bool>(
                      future: hasRequestSent(widget.currentmail, filteredUsers[index]['mail']),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        bool isRequestSent = requestSnapshot.data ?? false;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage('https://static.vecteezy.com/system/resources/thumbnails/026/497/734/small_2x/businessman-on-isolated-png.png'),
                            ),
                            contentPadding: EdgeInsets.all(10.0),
                            title: Text(filteredUsers[index]['name'] ?? 'Unknown'),
                            subtitle: Text(filteredUsers[index]['mail'] ?? 'Unknown Mail'),
                            trailing: ElevatedButton(
                              onPressed: isRequestSent
                                  ? null
                                  : () {
                                addFriend(context, filteredUsers[index]['mail']);
                                updateFriendRequest(widget.currentmail, filteredUsers[index]['mail']);
                                setState(() {

                                });
                                },
                              child: Text(isRequestSent ? 'Request Sent' : 'Add Friend'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void addFriend(BuildContext context, String userMail) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': widget.currentmail,
        'receiver': userMail,
        'status': 'pending',
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
}
