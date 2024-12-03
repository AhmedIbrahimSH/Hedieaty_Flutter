import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<Database> initializeDatabase() async {
  final Directory documentsDirectory = await getApplicationDocumentsDirectory();
  final String path = join(documentsDirectory.path, 'tahadow.db');

  return await openDatabase(
    path,
    version: 1,
    // onCreate: (Database db, int version) async {
    //
    //   await db.execute(
    //     'CREATE TABLE events(name TEXT PRIMARY KEY, date TEXT)',
    //   );
    //
    //   await db.execute(
    //     'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
    //
    //   );
    //
    // },
  );
}

Future<void> createTable(Database db, String tableName, Map<String, String> columns) async {
  // Construct the CREATE TABLE SQL statement dynamically
  final String columnDefinitions = columns.entries
      .map((entry) => '${entry.key} ${entry.value}')
      .join(', ');

  final String sql = 'CREATE TABLE IF NOT EXISTS $tableName($columnDefinitions)';

  try {
    // Execute the SQL command
    await db.execute(sql);
    print('Table "$tableName" created successfully.');
  } catch (e) {
    print('Error creating table "$tableName": $e');
  }
}



Future<void> addColumn(Database db, String tablename , String columnName, String columnType) async {
  // Add a new column to the "users" table
  try {
    await db.execute(
      'ALTER TABLE $tablename ADD COLUMN $columnName $columnType',
    );
    print('Column $columnName of type $columnType added successfully.');
  } catch (e) {
    print('Error adding column: $e');
  }
}

Future<void> insertUser(Database db, Map<String, dynamic> user) async {
  await db.insert(
    'users',
    user,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> fetchUsers(Database db) async {
  return await db.query('users');
}


Future<void> updateUser(Database db, Map<String, dynamic> user) async {
  await db.update(
    'users',
    user,
    where: 'id = ?',
    whereArgs: [user['id']],
  );
}


Future<void> deleteUser(Database db, int id) async {
  await db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> insertEvent(Database db, int userId, String eventName, String eventDate) async {
  await db.insert(
    'events',
    {
      'user_id': userId,
      'event_name': eventName,
      'event_date': eventDate,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  print('Event "$eventName" added successfully for user ID: $userId');
}

Future<List<Map<String, dynamic>>> fetchEventsForUser(Database db, int userId) async {
  return await db.query(
    'events',
    where: 'user_id = ?',
    whereArgs: [userId],
  );
}


Future<void> linkUserToFriends(Database db, String userName, List<String> friendNames) async {
  // Step 1: Get the user's ID (Mina's ID in this case)
  List<Map<String, dynamic>> userResult = await db.query(
    'users',
    where: 'name = ?',
    whereArgs: [userName],
  );

  if (userResult.isEmpty) {
    print('User not found');
    return;
  }

  int userId = userResult.first['id'];  // Mina's user_id

  // Step 2: Find friends' IDs and insert friendship links
  for (var friendName in friendNames) {
    List<Map<String, dynamic>> friendResult = await db.query(
      'users',
      where: 'name = ?',
      whereArgs: [friendName],
    );

    if (friendResult.isEmpty) {
      print('Friend $friendName not found');
      continue;
    }

    int friendId = friendResult.first['id'];  // Friend's user_id

    // Step 3: Insert friendship relationship (both directions)
    await db.insert('friendships', {
      'user_id': userId,
      'friend_id': friendId,
    });

    await db.insert('friendships', {
      'user_id': friendId,
      'friend_id': userId,
    });
  }

  print('Friendship links created successfully for $userName.');
}



void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database
  final db = await initializeDatabase();

  //
  //
  // await db.execute('DROP TABLE IF EXISTS events');
  //
  // await createTable(db, 'events', {
  //   'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
  //   'user_id': 'INTEGER',
  //   'event_name': 'TEXT',
  //   'event_date': 'TEXT',
  //   'FOREIGN KEY (user_id)': 'REFERENCES users(id) ON DELETE CASCADE',
  // });
  //
  //
  // await insertEvent(db, 2, 'first event' , '2024-12-23');
  // await insertEvent(db, 2, 'second event' , '2024-12-26');
  // await insertEvent(db, 2, 'third event' , '2024-12-25');
  // await insertEvent(db, 2, 'fourth event' , '2024-11-05');
  //
  //
  // await linkUserToFriends(db, 'Mina George', ['Ahmed Ali', 'Maria George']);

  List<Map<String, dynamic>> users = await fetchUsers(db);
  print(users);


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Database Example")),
        body: Center(child: Text("Check your database operations in the console")),
      ),
    );
  }
}
