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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Text',
        scaffoldBackgroundColor: Colors.grey.shade100,
        colorScheme: const ColorScheme.light(),
        textTheme: ThemeData.light().textTheme.copyWith(
          bodyMedium: const TextStyle(fontWeight: FontWeight.w200, color: Colors.black87),
          bodySmall: const TextStyle(fontWeight: FontWeight.w300, color: Colors.black87),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w200, color: Colors.black87),
          titleMedium: const TextStyle(fontWeight: FontWeight.w100, fontSize: 20, color: Colors.black87),
        ),      
      ),
      home: const FileExplorerPage(),
    );
  }
}
