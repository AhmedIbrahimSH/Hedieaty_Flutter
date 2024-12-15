import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PledgedGiftsPage extends StatefulWidget {
  final String currentUserMail;

  PledgedGiftsPage({required this.currentUserMail});

  @override
  _PledgedGiftsPageState createState() => _PledgedGiftsPageState(currentUserMail: this.currentUserMail);
}

class _PledgedGiftsPageState extends State<PledgedGiftsPage> {
  final String currentUserMail;
  late TextEditingController _searchController;
  late Stream<List<Map<String, dynamic>>> _pledgedGiftsStream;
  String searchQuery = "";

  _PledgedGiftsPageState({required this.currentUserMail});

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _pledgedGiftsStream = _getPledgedGiftsStream();
  }

  Stream<List<Map<String, dynamic>>> _getPledgedGiftsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserMail)
        .collection('pledged_gifts')
        .where('gift_owner', isGreaterThanOrEqualTo: searchQuery)
        .where('gift_owner', isLessThan: searchQuery + 'z')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pledged Gifts'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Gift Owner',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                  _pledgedGiftsStream = _getPledgedGiftsStream(); // Reload stream with new query
                });
              },
            ),
            SizedBox(height: 20),
            // Pledged Gifts list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _pledgedGiftsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No pledged gifts found.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var gift = snapshot.data![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          elevation: 5,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(gift['gift_name'] ?? 'No Gift Name'),
                            subtitle: Text('Owner: ${gift['gift_owner']}\nDue Date: ${gift['due_date']}'),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
