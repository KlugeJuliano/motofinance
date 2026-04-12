import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.lightBlueAccent,
        secondary: Colors.amber,
        surface: Color(0xFF000000),
      ),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'Roboto',
        ),
        bodyLarge: TextStyle(
          color: Colors.white70,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.blueGrey,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}
