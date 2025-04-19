import 'package:flutter/material.dart';
import 'pages/file_explorer_page.dart';

void main() {
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
          bodyMedium: const TextStyle(fontWeight: FontWeight.w200),
          bodySmall: const TextStyle(fontWeight: FontWeight.w200),
          bodyLarge: const TextStyle(fontWeight: FontWeight.w200),
          titleMedium: const TextStyle(fontWeight: FontWeight.w100),
        ),      
      ),
      home: const FileExplorerPage(),
    );
  }
}
