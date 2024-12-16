import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class _GiftTile extends StatefulWidget {
  final Map<String, dynamic> gift;

  const _GiftTile({Key? key, required this.gift}) : super(key: key);

  @override
  __GiftTileState createState() => __GiftTileState();
}

class __GiftTileState extends State<_GiftTile> {
  bool isPledged = false;

  Stream<bool> _giftStatusStream() async* {
    await Future.delayed(Duration(seconds: 1));  // Simulating delay
    yield isPledged; // Yield the current pledge status
  }

  // Function to handle pledge action
  void _handlePledge() async {
    bool? isConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pledge Confirmation'),
          content: Text('Are you sure you want to pledge this gift?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed "No"
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed "Yes"
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (isConfirmed == true) {
      setState(() {
        isPledged = true;
      });
      print("Gift pledged: ${widget.gift['gift_name']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _giftStatusStream(),  // Listen to the status stream
      builder: (context, snapshot) {
        bool pledged = snapshot.data ?? isPledged;  // Default to current pledge status if no data

        return ListTile(
          title: Text(widget.gift['gift_name'] ?? 'Unnamed Gift'),
          subtitle: SingleChildScrollView(  // Wrap the content in a SingleChildScrollView
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price: \$${widget.gift['price']}'),
                Text('Status: ${widget.gift['status']}'),
                Text('Link:'),
                GestureDetector(
                  onTap: () async {
                    final url = widget.gift['link'];
                    if (url != null && await canLaunch(url)) {
                      bool? openLink = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('External Link'),
                            content: Text('You will leave the app to open an external link. Do you want to continue?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false); // Stay in the app
                                },
                                child: Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true); // Leave the app
                                },
                                child: Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );

                      if (openLink == true) {
                        await launch(url);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Invalid or missing URL'),
                      ));
                    }
                  },
                  child: Text(
                    widget.gift['link'] ?? 'No link available',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              pledged ? Icons.check_circle : Icons.card_giftcard, // Show a check mark if pledged
              color: pledged ? Colors.green : Colors.blue, // Change color based on pledge status
            ),
            onPressed: _handlePledge, // Show confirmation dialog
          ),
        );
      },
    );
  }
}
