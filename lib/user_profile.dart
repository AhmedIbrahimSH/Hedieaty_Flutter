import 'package:app/local_database/local_sql_init.dart';
import 'package:app/user_nots.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'current_logged_user/pledged_gifts.dart';
import 'events/list_user_events.dart';

class ProfilePage extends StatefulWidget {
  final String currentUserMail;
  LocalDatabase localdb;
  ProfilePage({required this.currentUserMail, required this.localdb});

  @override
  _ProfilePageState createState() => _ProfilePageState(db: this.localdb);
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late Future<List<Map<String, dynamic>>> _friendsFuture;
  late LocalDatabase db;
  _ProfilePageState({required this.db});
  bool _isEditing = false;
  bool _isPasswordVisible = false;
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

  void reloadFriends() {
    setState(() {
      _friendsFuture = fetchFriends();
    });
  }
  @override
  void initState() {
    super.initState();
    _mailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .get();

      if (doc.exists) {
        var data = doc.data();
        setState(() {
          _mailController.text = data?['mail'] ?? '';
          _phoneController.text = data?['phone'] ?? '';
          _passwordController.text = data?['password'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> _updateUserDetails() async {
    if (!_isEditing) return;

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserMail)
            .update({
          'name': _mailController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully.')));

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  void dispose() {
    _mailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateUserDetails,
            ),
          IconButton(
            icon: Icon(Icons.event),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(

                  builder: (context) =>  EventsPage(currentUserMail: widget.currentUserMail, localdb: this.db),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.card_giftcard_sharp),
            onPressed: (){

              Navigator.push(
                context,
                MaterialPageRoute(

                  builder: (context) =>  PledgedGiftsPage(currentUserMail: widget.currentUserMail),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                margin: EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _mailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        readOnly: !_isEditing,
                        onSaved: (value) {
                          _mailController.text = value!;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                margin: EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        readOnly: !_isEditing,
                        onSaved: (value) {
                          _phoneController.text = value!;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                margin: EdgeInsets.only(bottom: 15),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          suffixIcon: _isEditing
                              ? IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          )
                              : null,
                        ),
                        obscureText: !_isPasswordVisible,
                        readOnly: !_isEditing,
                        onSaved: (value) {
                          _passwordController.text = value!;
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                child: Text(_isEditing ? 'Cancel' : 'Edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
