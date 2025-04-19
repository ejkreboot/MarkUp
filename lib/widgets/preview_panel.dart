import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class PreviewPanel extends StatelessWidget {
  final FileSystemEntity? selectedFile;
  final void Function() onClose;

  const PreviewPanel({super.key, required this.selectedFile, required this.onClose});

  @override
  Widget build(BuildContext context) {
    if (selectedFile == null || selectedFile is Directory) {
      return const Center(child: Text('Select a file to preview'));
    }

    final file = selectedFile!;
    final name = p.basename(file.path);
    final size = File(file.path).lengthSync();
    final isSvg = file.path.toLowerCase().endsWith('.svg');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Type: ${isSvg ? 'SVG' : 'File'}'),
              Text('Size: $size bytes'),
              const SizedBox(height: 16),
              if (isSvg)
                SvgPicture.file(File(file.path), width: 240, height: 320)
              else
                const Center(child: Icon(Icons.insert_drive_file_outlined, size: 100)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: onClose,
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
