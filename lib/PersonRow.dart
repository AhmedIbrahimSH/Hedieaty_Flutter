import 'package:flutter/material.dart';

class PersonRow extends StatelessWidget {
  final Map<String, dynamic> person;
  final String currentUserMail;
  final dynamic Function(String, String)? onAddFriend; // Allow null value
  final List<Map<String, dynamic>> users;

  PersonRow({
    required this.person,
    required this.currentUserMail,
    this.onAddFriend,
    required this.users, required FutureBuilder<int> trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    String name = person['name'] ?? 'Unknown';
    String mail = person['mail'] ?? 'Unknown Mail';
    String phone = person['phone'] ?? 'Unknown Phone';
    String avatar = person['avatar'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(10.0),
        leading: CircleAvatar(
          backgroundImage: avatar.isNotEmpty
              ? NetworkImage(avatar)
              : AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name),
            Text(mail, style: TextStyle(fontSize: 12)),
          ],
        ),
        subtitle: Text(phone),
        trailing: GestureDetector(
          onTap: () {
            onAddFriend!(currentUserMail, mail);
          },
          child: ElevatedButton(
            onPressed: () {
            },
            child: Text('Add Friend'),
          ),
        ),
      ),
    );
  }
}

