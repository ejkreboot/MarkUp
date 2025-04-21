import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class FileList extends StatelessWidget {
  final List<FileSystemEntity> entries;
  final String currentPath;
  final void Function(String path) onDirectoryTap;
  final void Function(FileSystemEntity file) onFileTap;

  const FileList({
    super.key,
    required this.entries,
    required this.currentPath,
    required this.onDirectoryTap,
    required this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.25),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: 
                  Text(
                    "   $currentPath",
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Modified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entity = entries[index];
                final path = entity.path;
                final name = p.basename(path);
                final isUpEntry = name == '..';
                final isDir = FileSystemEntity.isDirectorySync(path);
                DateTime? modified;

                if (isUpEntry) {
                  return _buildUpEntry(
                    context,
                    () => onDirectoryTap(Directory(currentPath).parent.path),
                  );
                }

                try {
                  modified = File(path).lastModifiedSync();
                } catch (_) {}

                return Draggable<FileSystemEntity>(
                  data: entity,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDir ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: _buildFileRow(context, entity, name, isDir, modified, index),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (isDir) {
                        onDirectoryTap(path);
                      } else {
                        onFileTap(entity);
                      }
                    },
                    child: _buildFileRow(context, entity, name, isDir, modified, index),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildFileRow(
    BuildContext context,
    FileSystemEntity entity,
    String name,
    bool isDir,
    DateTime? modified,
    int index,
  ) {
    return Container(
      width: double.infinity,  // <-- FULL WIDTH background
      color: index.isEven ? const Color.fromARGB(255, 252, 252, 252) : Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8.0),  // Top and bottom breathing
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),  // <-- NEW: left-side breathing room
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: isDir
                        ? const Icon(Icons.folder_outlined, size: 20, color: Colors.black87)
                        : const Icon(Icons.insert_drive_file_outlined, size: 20, color: Colors.black87),
                  ),
                  Flexible(
                    child: Container (
                      constraints: BoxConstraints(maxWidth: 300, minWidth: 300, ),
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, 
                                               color: Colors.black87, 
                                               fontWeight:  FontWeight.w300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: modified != null
                  ? Text(
                      '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpEntry(BuildContext context, VoidCallback onTap) {
    return Container(
      color: const Color.fromARGB(255, 252, 252, 252),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Icon(Icons.arrow_upward, size: 20),
                  ),
                  Flexible(
                    child: Text(
                      '..',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(flex: 1, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
