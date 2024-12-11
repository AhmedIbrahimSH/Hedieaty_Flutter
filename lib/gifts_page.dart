import 'package:flutter/material.dart';


class GiftListPage extends StatefulWidget {
  final Map<String, dynamic> person;

  GiftListPage({required this.person});

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  late List<String> giftList;
  final TextEditingController giftController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<String> filteredGiftList = [];

  @override
  void initState() {
    super.initState();
    giftList = List<String>.from(widget.person['gifts']);
    filteredGiftList = List<String>.from(giftList);
  }

  void _pledgeGift(String gift) {
    setState(() {
      giftList.add(gift);
      filteredGiftList = List<String>.from(giftList);
    });
    giftController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pledged a gift: $gift')),
    );
  }

  void _searchGifts(String query) {
    setState(() {
      filteredGiftList = giftList
          .where((gift) => gift.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.person['name']}'s Gift List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: _searchGifts,
              decoration: InputDecoration(
                hintText: "Search gifts",
                labelText: 'Search Gifts',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGiftList.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(filteredGiftList[index]));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: giftController,
                    decoration: InputDecoration(hintText: "Enter a new gift"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _pledgeGift(giftController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
