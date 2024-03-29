import 'package:flutter/material.dart';
import 'root_page.dart';
import 'auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Today\'s Words',
        theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.green[800],
            accentColor: Colors.greenAccent[400],

            primarySwatch: Colors.green,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.accent),

            fontFamily: 'Helvetica',

            textTheme: TextTheme(
                headline: TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
                title: TextStyle(fontSize: 30.0),
                button: TextStyle(
                    color: Colors.green, // This is not working.
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold
                )
            )
        ),
        home: new RootPage(auth: new Auth())
    );
  }
}