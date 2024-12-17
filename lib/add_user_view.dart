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
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10.0),
                        title: Text(filteredUsers[index]['name'] ?? 'Unknown'),
                        subtitle: Text(filteredUsers[index]['mail'] ?? 'Unknown Mail'),
                        trailing: StatefulBuilder(  // StatefulBuilder for button state
                          builder: (context, setButtonState) {
                            bool isRequestSent = false;

                            return ElevatedButton(
                              onPressed: () {
                                if (!isRequestSent) {
                                  addFriend(context, filteredUsers[index]['mail']);
                                  setButtonState(() {
                                    isRequestSent = true; // Update button state
                                  });
                                }
                              },
                              child: Text(isRequestSent ? 'Request Sent' : 'Add Friend'),
                            );
                          },
                        ),
                      ),
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
      // Create a notification for the receiver that there's a pending friend request
      await FirebaseFirestore.instance.collection('notifications').add({
        'sender': widget.currentmail,
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
}
