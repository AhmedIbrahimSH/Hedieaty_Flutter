import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';

class LocalDatabase {
  late Database db;

  Future<void> initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'local_db.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          mail TEXT PRIMARY KEY,
          name TEXT,
          password TEXT,
          phone TEXT,
          profile_pic TEXT
        );
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mail TEXT,
          date TEXT,
          name TEXT,
          FOREIGN KEY (mail) REFERENCES users (mail)
        );
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS gifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mail TEXT,
          event_name TEXT,
          category TEXT,
          gift_image_url TEXT,
          gift_name TEXT,
          gift_owner TEXT,
          link TEXT,
          price REAL,
          status TEXT,
          FOREIGN KEY (mail) REFERENCES users (mail),
          FOREIGN KEY (event_name) REFERENCES events (name)
        );
      ''');
      },
    );
  }

  Future<void> deleteTables() async {
    await db.execute('DROP TABLE IF EXISTS gifts;');
    await db.execute('DROP TABLE IF EXISTS events;');
    await db.execute('DROP TABLE IF EXISTS users;');
    print('Tables deleted successfully.');
  }

  Future<List<Map<String, dynamic>>> getLocalEvents(String mail) async {
    List<Map<String, dynamic>> events = await db.query(
      'events',
      where: 'mail = ?',
      whereArgs: [mail],
    );
    print("fetched ${events}");
    return events;
  }

  Future<void> insertGiftLocally(
  String eventName, String giftName,
  double price,
  String giftLink,
  String selectedCategory,
  String imagePath,
  String currentUserMail,
      ) async {
    print("------------");
    print(eventName);
    print(giftLink);
    print(giftName);
    print(selectedCategory);
    print(price);
    print(imagePath);
    print(currentUserMail);

    await db.insert(
      'gifts',
      {
        'event_name': eventName,
        'gift_name': giftName,
        'price': price,
        'link': giftLink,
        'category': selectedCategory,
        'gift_image_url': imagePath,
        'status': 'wanted',
        'gift_owner': currentUserMail,
        'mail': currentUserMail,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


    Future<void> insertEventLocally(String mail, String date, String name) async {
    try {
      List<Map<String, dynamic>> existingEvent = await db.query(
        'events',
        where: 'mail = ? AND date = ? AND name = ?',
        whereArgs: [mail, date, name],
      );

      if (existingEvent.isEmpty) {
        await db.insert(
          'events',
          {
            'mail': mail,
            'date': date,
            'name': name,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('Event added: $name');
      } else {
        print('Event with the same name and date already exists for the user.');
      }
    } catch (e) {
      print('Error inserting event: $e');
    }
  }

  Future<void> deleteEvent({
    required String mail,
    required String eventName,
  }) async {
    try {
      // Delete event from Firebase
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Find the specific event document in Firebase
      QuerySnapshot eventSnapshot = await firestore
          .collection('users')
          .doc(mail)
          .collection('events')
          .where('name', isEqualTo: eventName)
          .get();

      for (QueryDocumentSnapshot eventDoc in eventSnapshot.docs) {
        // Delete the event document
        await firestore
            .collection('users')
            .doc(mail)
            .collection('events')
            .doc(eventDoc.id)
            .delete();

        // Also delete associated gifts from Firebase
        QuerySnapshot giftSnapshot = await firestore
            .collection('users')
            .doc(mail)
            .collection('events')
            .doc(eventDoc.id)
            .collection('gifts')
            .get();

        for (QueryDocumentSnapshot giftDoc in giftSnapshot.docs) {
          await firestore
              .collection('users')
              .doc(mail)
              .collection('events')
              .doc(eventDoc.id)
              .collection('gifts')
              .doc(giftDoc.id)
              .delete();
        }
      }

      // Delete event from the local SQLite database
      int deletedRows = await db.delete(
        'events',
        where: 'mail = ? AND name = ?',
        whereArgs: [mail, eventName],
      );

      if (deletedRows > 0) {
        await db.delete(
          'gifts',
          where: 'mail = ? AND event_name = ?',
          whereArgs: [mail, eventName],
        );
        print('Event "$eventName" deleted locally and in Firebase.');
      } else {
        print('Event "$eventName" not found locally but deleted in Firebase.');
      }
    } catch (e) {
      print('Error deleting event: $e');
    }
  }



  Future<List<Map<String, dynamic>>> getEventsForUser(String mail) async {
    try {
      List<Map<String, dynamic>> events = await db.query(
        'events',
        where: 'mail = ?',
        whereArgs: [mail],
        orderBy: 'date DESC', // Sort by the 'date' column in descending order
      );

      return events;
    } catch (e) {
      print('Error fetching events for user: $e');
      return [];
    }
  }


  Future<bool> isEventInFirebase(String mail, String eventName) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot eventSnapshot = await firestore
          .collection('users')
          .doc(mail)
          .collection('events')
          .where('name', isEqualTo: eventName)
          .get();
      print("checking ${eventName} ${eventSnapshot.docs.isNotEmpty}");
      return eventSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking Firebase: $e');
      return false;
    }
  }

  // Add event to Firebase
  Future<void> insertEventToFirebase(String mail, String eventName, String date) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.collection('users').doc(mail).collection('events').add({
          'date': date,
          'name': eventName,
        });

        print('Event added to Firebase: ${eventName}');

    } catch (e) {
      print('Error inserting event to Firebase: $e');
    }
  }






  Future<void> populateTables(String mail) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    List<Map<String, dynamic>> existingUser = await db.query(
      'users',
      where: 'mail = ?',
      whereArgs: [mail],
    );

    if (existingUser.isEmpty) {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(mail).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        await db.insert('users', {
          'mail': userData['mail'],
          'name': userData['name'],
          'password': userData['password'],
          'phone': userData['phone'],
          'profile_pic': userData['profile_pic'],
        });
      }
    }

    QuerySnapshot eventSnapshot = await firestore
        .collection('users')
        .doc(mail)
        .collection('events')
        .get();

    for (QueryDocumentSnapshot eventDoc in eventSnapshot.docs) {
      Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> existingEvent = await db.query(
        'events',
        where: 'mail = ? AND name = ?',
        whereArgs: [mail, eventData['name']],
      );

      if (existingEvent.isEmpty) {
        await db.insert('events', {
          'mail': mail,
          'date': eventData['date'],
          'name': eventData['name'],
        });

        QuerySnapshot giftSnapshot = await firestore
            .collection('users')
            .doc(mail)
            .collection('events')
            .doc(eventDoc.id)
            .collection('gifts')
            .get();

        for (QueryDocumentSnapshot giftDoc in giftSnapshot.docs) {
          Map<String, dynamic> giftData = giftDoc.data() as Map<String, dynamic>;

          List<Map<String, dynamic>> existingGift = await db.query(
            'gifts',
            where: 'mail = ? AND event_name = ? AND gift_name = ?',
            whereArgs: [mail, eventData['name'], giftData['gift_name']],
          );

          if (existingGift.isEmpty) {
            await db.insert('gifts', {
              'mail': mail,
              'event_name': eventData['name'],
              'category': giftData['category'],
              'gift_image_url': giftData['gift_image_url'],
              'gift_name': giftData['gift_name'],
              'gift_owner': giftData['gift_owner'],
              'link': giftData['link'],
              'price': giftData['price'],
              'status': giftData['status'],
            });
          }
        }
      }
    }

    print('Users Table:');
    List<Map<String, dynamic>> users = await db.query('users');
    print(users);

    print('Events Table:');
    List<Map<String, dynamic>> events = await db.query('events');
    print(events);

    print('Gifts Table:');
    List<Map<String, dynamic>> gifts = await db.query('gifts');
    print(gifts);
  }

}







Future<LocalDatabase> init_local_db(usermail) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  LocalDatabase localDb = LocalDatabase();
  await localDb.initializeDatabase();

  String loggedInUserMail = usermail;

  await localDb.populateTables(loggedInUserMail);

  return localDb;
  //
  // await localDb.deleteTables();
  //
  // String path = join(await getDatabasesPath(), 'app_database.db');
  // await deleteDatabase(path); // Deletes the existing database

}


