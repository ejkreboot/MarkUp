import 'package:flutter/material.dart';
import 'pages/file_explorer_page.dart';
import 'package:window_size/window_size.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('MarkUp');
    setWindowMinSize(const Size(1000, 700)); 
    setWindowMaxSize(Size.infinite);
    setWindowFrame(const Rect.fromLTWH(100, 100, 1000, 700)); 
  }
  runApp(const MarkUpApp());
}

class MarkUpApp extends StatelessWidget {
  const MarkUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarkUp',
      theme: _buildMarkUpTheme(),
      home: const FileExplorerPage(),
    );
  }
}

ThemeData _buildMarkUpTheme() {
  const primaryColor = Color(0xFF333333); // Deep gray
  const secondaryColor = Color(0xFF666666); // Softer gray
  const accentColor = Color(0xFF0099FF); // Subtle blue for active elements
  const lightColor = Color.fromARGB(255, 245, 245, 245);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'SF Pro Text',
    scaffoldBackgroundColor: Colors.grey.shade100,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w300),
      bodySmall: TextStyle(color: secondaryColor, fontSize: 12, fontWeight: FontWeight.w300),
      titleLarge: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w200),
      titleSmall: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        borderSide: BorderSide(color: Color.fromARGB(255, 81, 81, 81), width: 2),
      ),
      filled: true,
      fillColor: Color(0xFFF2F2F2),
      labelStyle: TextStyle(
        color: secondaryColor,
        fontWeight: FontWeight.w200,
      ),
      floatingLabelStyle: TextStyle(
        color: secondaryColor,
        fontSize: 14,
      ),
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      elevation: 2,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        backgroundColor: lightColor,
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    dialogTheme: const DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)), // <-- Adjust radius here
      ),
      backgroundColor: Colors.white,
      elevation: 4,
    ),
  );
}

