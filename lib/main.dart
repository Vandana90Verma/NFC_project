import 'package:flutter/material.dart';
import 'homePage.dart';



void main() async{
  runApp(  MyApp());
}

class MyApp extends StatefulWidget {
    MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:   MyHomePage(title: 'Student Detail',rollNumber: 1234566789.toString(),),
    );
  }
}


