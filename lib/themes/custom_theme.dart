import 'package:flutter/material.dart';

class CustomTheme {
   static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black12,
        foregroundColor: Colors.black12,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Roboto'),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.blueGrey,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}