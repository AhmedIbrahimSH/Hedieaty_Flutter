import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'local_database/local_sql_init.dart'; // Import SQLite for local database

class CalendarPage extends StatefulWidget {
  final String currentUserMail;
  LocalDatabase localdb;
  CalendarPage({required this.currentUserMail, required this.localdb});

  @override
  _CalendarPageState createState() => _CalendarPageState(localdb: this.localdb);
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _eventNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showToFriends = false; // Add a variable for the checkbox
  LocalDatabase localdb;
  _CalendarPageState({required this.localdb});
  Future<void> saveEvent() async {
    try {
      // Format the date in 'yyyy-MM-dd' format
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Check if event should be saved to Firestore and/or local database
      if (_showToFriends) {
        // Add event to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUserMail)
            .collection('events')
            .add({
          'name': _eventNameController.text,
          'date': formattedDate, // Store the date in 'yyyy-MM-dd' format
          'showToFriends': _showToFriends, // Store the checkbox value
        });

        // // Show success message
        // ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        //   SnackBar(
        //     content: Text('Event added to Firestore successfully!'),
        //     duration: Duration(seconds: 5),
        //   ),
        // );
      }

      // Save to local database regardless of checkbox state
      await saveEventLocally();

      // // Show a success message for local database save
      // ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      //   SnackBar(
      //     content: Text('Event saved locally successfully!'),
      //     duration: Duration(seconds: 5),
      //   ),
      // );

      // Go back to the homepage
      // Navigator.pop(context as BuildContext); // Make sure `context` is of type `BuildContext`
    } catch (e) {
      // Handle error
      print("Error adding event: $e");
    }
  }


  Future<void> saveEventLocally() async {
    try {
      // Format the date in 'yyyy-MM-dd' format
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Insert event data into the events table in the local database
      await localdb?.insertEventLocally(
           widget.currentUserMail, // User's email (from widget)
           formattedDate, // Formatted date of the event
          _eventNameController.text, // Event name
      );
      print("Event added succesffully to local");

      // Show success message as a SnackBar
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Event added to local database!'),
      //     duration: Duration(seconds: 5),
      //   ),
      // );

      // Go back to the homepage
      // Navigator.pop(context);
    } catch (e) {
      // Handle error
      print("Error adding event to local database: $e");
    }
  }


  // Function to select date with a minimum date of today
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(), // Minimum date is today
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Event'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventNameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                prefixIcon: Icon(Icons.event), // Added icon beside the text field
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "Event Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}", // Display date in 'yyyy-MM-dd' format
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Checkbox to show event to friends
            Row(
              children: [
                Checkbox(
                  value: _showToFriends,
                  onChanged: (bool? value) {
                    setState(() {
                      _showToFriends = value ?? false;
                    });
                  },
                ),
                Text('Show to friends'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveEvent,
              child: Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }
}
