import 'package:app/friends_events.dart';
import 'package:app/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_event.dart';
import 'add_user_view.dart';
import 'events/list_user_events.dart';
import 'user_nots.dart';

class HomePage extends StatefulWidget {
  final String currentUserMail;

  HomePage({required this.currentUserMail});

  @override
  _HomePageState createState() => _HomePageState(currentUserMail: this.currentUserMail);
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  final String? currentUserMail;
  _HomePageState({required this.currentUserMail});
  @override
  void initState() {
    super.initState();
    _friendsFuture = fetchFriends();
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('friendships')
          .get();

      List<String> friendsMails = snapshot.docs
          .map((doc) => doc['mail'] as String)
          .toList();

      if (friendsMails.isEmpty) {
        return [];
      }

      var friendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('mail', whereIn: friendsMails)
          .get();

      return friendsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception("Error fetching friends: $e");
    }
  }

  // Function to get the count of unread notifications
  Future<int> getUnreadNotificationsCount() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('receiver', isEqualTo: widget.currentUserMail)
          .where('status', isEqualTo: 'pending') // only unread notifications
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0; // In case of an error, return 0 unread notifications
    }
  }

  // Function to reload friends list
  void reloadFriends() {
    setState(() {
      _friendsFuture = fetchFriends();
    });
  }

  // Function to handle notification button click
  void _onNotificationsClicked() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(currentmail: widget.currentUserMail),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete', style: TextStyle(color: Colors.red)),
          content: Text('Are you sure you want to remove this friend?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // No
              },
              child: Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Yes
              },
              child: Text('Yes', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    ) ??
        false; // In case the dialog is closed without a selection, return false.
  }

  Future<int> getUpcomingEventsCount(String friendMail) async {
    try {
      // Get today's date as a string in the same format as stored in the database
      var today = DateTime.now();
      String todayString = "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      // Query the events subcollection with a string comparison
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('mail', isEqualTo: friendMail)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0; // No user found with this email
      }

      // Assume there is only one user with this email
      var userDocId = snapshot.docs.first.id;

      var eventsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDocId)
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: todayString)
          .get();

      return eventsSnapshot.docs.length;
    } catch (e) {
      return 0; // Return 0 if there are errors
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.teal,
        actions: [
          // Notifications icon with count
          FutureBuilder<int>(
            future: getUnreadNotificationsCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: _onNotificationsClicked,
                );
              }

              int unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: _onNotificationsClicked,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: reloadFriends,
          ),
          IconButton(
            icon: Icon(Icons.event),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(

                  builder: (context) =>  EventsPage(currentUserMail: widget.currentUserMail),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(currentUserMail: widget.currentUserMail),
                ),
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _friendsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No friends found.'));
            }

            var friends = snapshot.data!;

            return ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                var friend = friends[index];
                String friendMail = friend['mail'];

                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(friend['mail'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(friend['mail']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<int>(
                          future: getUpcomingEventsCount(friendMail),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            int eventCount = snapshot.data ?? 0;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventPage(userMail: friendMail , current_logged_mail: currentUserMail),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.teal,
                                child: Text(
                                  '$eventCount',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle),
                          onPressed: () async {
                            try {
                              // Remove the friend from the current user's "friendships" collection
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.currentUserMail)
                                  .collection('friendships')
                                  .doc(friendMail)
                                  .delete();

                              // Remove the current user from the friend's "friendships" collection
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(friendMail)
                                  .collection('friendships')
                                  .doc(widget.currentUserMail)
                                  .delete();

                              // Optionally, reload the friends list to reflect the changes
                              reloadFriends();
                            } catch (e) {
                              // Handle any errors that occur while removing the friend
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error removing friend: $e")),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Button to show current user's events
          FloatingActionButton(
            heroTag: 'userEvents',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarPage(currentUserMail: widget.currentUserMail)
                ),
              );
            },
            child: Icon(Icons.event_note),
            backgroundColor: Colors.blue,
            tooltip: 'My Events',
          ),
          SizedBox(height: 10), // Space between buttons
          // Existing button to add friends
          FloatingActionButton(
            heroTag: 'addFriend',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsersPage(currentmail: widget.currentUserMail),
                ),
              );
            },
            child: Icon(Icons.add),
            backgroundColor: Colors.teal,
            tooltip: 'Add Friend',
          ),
        ],
      ),
    );
  }

}
