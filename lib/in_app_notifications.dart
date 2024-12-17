import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Notifications',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForNotifications() {
    final String currentUserEmail = 'ahhmed@gmail.com';
    FirebaseFirestore.instance.collection('notifications').snapshots().listen((snapshot) {

      for (var doc in snapshot.docs) {
        var notification = doc.data();


        print(notification['receiver']);
        print(notification['message']);
        String? type = notification['type'];
        String? receiver = notification['receiver'];
        // String? pledgerer = notification['pledgerer'];
        String? message = notification['message'];

        if (type != null && message != null) {
          if (type == 'frequest' && receiver != null && receiver == currentUserEmail) {
            _showNotification(message);
          }
          // } else if (type == 'pledge' && pledgerer != null && pledgerer == currentUserEmail) {
          //   _showNotification(message);
          // }
        }
      }
    });
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Notification',
      message,
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Notifications'),
      ),
      body: Center(
        child: Text('Listening for Notifications...'),
      ),
    );
  }
}
