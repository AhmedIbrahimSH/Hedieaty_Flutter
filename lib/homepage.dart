import 'package:app/user_events.dart';
import 'package:app/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_event.dart';
import 'add_user_view.dart';
import 'user_nots.dart';

class HomePage extends StatefulWidget {
  final String currentUserMail;

  HomePage({required this.currentUserMail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = fetchFriends();
  }

  // Function to fetch friends of the current user
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
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
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: reloadFriends,
          ),
          // Add Event button
          IconButton(
            icon: Icon(Icons.event),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarPage(currentUserMail: widget.currentUserMail),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(currentUserMail: widget.currentUserMail,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
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

              return ListTile(
                subtitle: Text(friend['mail']),
                trailing: IconButton(
                  icon: Icon(Icons.event),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventPage(userMail: friendMail),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsersPage(currentmail: widget.currentUserMail),
            ),
          );
        },
        child: Icon(Icons.person_add),
        tooltip: 'Add Friend',
      ),
    );
  }
}
