import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class ProfileUpdatePage extends StatefulWidget {
  final int userId;
  ProfileUpdatePage({required this.userId});

  @override
  _ProfileUpdatePageState createState() => _ProfileUpdatePageState();
}

class _ProfileUpdatePageState extends State<ProfileUpdatePage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  bool _notificationStatus = false;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load the current user data from SQLite
  void _loadUserData() async {
    var user = await DatabaseHelper().getUser(widget.userId);
    if (user != null) {
      setState(() {
        _nameController.text = user['name'];
        _ageController.text = user['age'].toString();
        _phoneController.text = user['phone'];
        _notificationStatus = user['notstatus'] == 1;
      });
    }
  }

  // Save user data and update in the database
  void _saveUserData() {
    String name = _nameController.text;
    int age = int.tryParse(_ageController.text) ?? 0;
    String phone = _phoneController.text;
    int notstatus = _notificationStatus ? 1 : 0;

    if (_isEdited) {
      DatabaseHelper().updateUser(
        widget.userId,
        name,
        age,
        phone,
        notstatus,
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile Updated')));
      });
    }
  }

  // Confirm user action when navigating back with unsaved changes
  Future<bool> _onWillPop() async {
    if (_isEdited) {
      return (await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes'),
          content: Text('Your changes will be lost. Do you want to go back?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Discard'),
            ),
          ],
        ),
      )) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit Profile"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (_) => setState(() => _isEdited = true),
              ),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _isEdited = true),
              ),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                onChanged: (_) => setState(() => _isEdited = true),
              ),
              Row(
                children: [
                  Text('Notifications'),
                  Switch(
                    value: _notificationStatus,
                    onChanged: (value) {
                      setState(() {
                        _notificationStatus = value;
                        _isEdited = true;
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _saveUserData();
                  setState(() {
                    _isEdited = false;
                  });
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
