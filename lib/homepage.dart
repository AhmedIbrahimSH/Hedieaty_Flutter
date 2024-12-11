import 'package:app/user_events.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'add_user_view.dart';
import 'user_nots.dart';

class HomePage extends StatefulWidget {
  final String currentUserMail;

  HomePage({required this.currentUserMail});

  @override
  _HomePageState createState() => _HomePageState(currentUserMail);
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  String currentUserMail = "";

  _HomePageState(String currentUserMail) {
    this.currentUserMail = currentUserMail;
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
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
  }

  Future<int> getUnreadNotificationsCount() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiver', isEqualTo: widget.currentUserMail)
        .where('status', isEqualTo: 'pending') // only unread notifications
        .get();

    return snapshot.docs.length;
  }

  @override
  void initState() {
    super.initState();
    _friendsFuture = fetchFriends();
  }

  void reloadFriends() {
    setState(() {
      _friendsFuture = fetchFriends();
    });
  }

  // Function to handle notification button click
  void _onNotificationsClicked() {
    print("Notifications clicked");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(currentmail: this.currentUserMail),
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
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: reloadFriends,
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
              builder: (context) => UsersPage(currentmail: currentUserMail),
            ),
          );
        },
        child: Icon(Icons.person_add),
        tooltip: 'Add Friend',
      ),
    );
  }
}
