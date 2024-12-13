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
        isPledged = true; // Change the icon to indicate the gift has been pledged
      });
      // You can call any function here to "commit" the pledge action
      print("Gift pledged: ${widget.gift['gift_name']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.gift['gift_name'] ?? 'Unnamed Gift'),
      subtitle: Column(
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
      trailing: IconButton(
        icon: Icon(
          isPledged ? Icons.check_circle : Icons.card_giftcard, // Show a check mark if pledged
          color: isPledged ? Colors.green : Colors.blue, // Change color based on pledge status
        ),
        onPressed: _handlePledge, // Show confirmation dialog
      ),
    );
  }
}
