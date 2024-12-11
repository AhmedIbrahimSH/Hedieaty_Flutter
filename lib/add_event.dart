import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Import the intl package

class CalendarPage extends StatefulWidget {
  final String currentUserMail;

  CalendarPage({required this.currentUserMail});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _eventNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Function to save the event to Firestore
  Future<void> saveEvent() async {
    try {
      // Format the date in 'yyyy-MM-dd' format
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Add event to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserMail)
          .collection('events')
          .add({
        'name': _eventNameController.text,
        'date': formattedDate, // Store the date in 'yyyy-MM-dd' format
      });

      // Go back to the home page after saving the event
      Navigator.pop(context);
    } catch (e) {
      // Handle error
      print("Error adding event: $e");
    }
  }

  // Function to select date with a minimum date of today
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),  // Minimum date is today
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
              decoration: InputDecoration(labelText: 'Event Name'),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "Event Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",  // Display date in 'yyyy-MM-dd' format
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
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
