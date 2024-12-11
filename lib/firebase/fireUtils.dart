import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future <void> fetchuser() async{
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('todos').get();
  for(var doc in querySnapshot.docs)
  {
    print(doc.data());
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await fetchuser();
}

