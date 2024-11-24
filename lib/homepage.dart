import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  // Sample data for the list
  final List<Map<String, String>> people = [
    {'name': 'Mariam Hassan', 'avatar': 'https://i.pravatar.cc/150?img=1'},
    {'name': 'Mina George', 'avatar': 'https://i.pravatar.cc/150?img=2'},
    {'name': 'Hazem Mohamed', 'avatar': 'https://i.pravatar.cc/150?img=3'},
    {'name': 'Mazen Ali', 'avatar': 'https://i.pravatar.cc/150?img=4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upcoming Events')),
      body: ListView.builder(
        itemCount: people.length,
        itemBuilder: (context, index) {
          return PersonRow(person: people[index]);
        },
      ),
    );
  }
}

class PersonRow extends StatefulWidget {
  final Map<String, String> person;

  PersonRow({required this.person});

  @override
  _PersonRowState createState() => _PersonRowState();
}

class _PersonRowState extends State<PersonRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.person['avatar']!),
        ),
        title: Text(widget.person['name']!),
        trailing: IconButton(
          icon: Icon(Icons.info),
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        subtitle: _isExpanded
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Text('Details about ${widget.person['name']}'),
            SizedBox(height: 5),
            Text('More information here...'),
          ],
        )
            : null,
      ),
    );
  }
}
