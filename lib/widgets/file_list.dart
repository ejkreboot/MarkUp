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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text('File Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 1,
                  child: Text('Modified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(
                color: Colors.grey.shade300,
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                final entity = entries[index];
                final path = entity.path;
                final name = p.basename(path);
                final isUpEntry = name == '..';

                if (isUpEntry) {
                  return InkWell(
                    onTap: () => onDirectoryTap(Directory(currentPath).parent.path),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Icon(Icons.arrow_upward, size: 20),
                                SizedBox(width: 8),
                                Text('..', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
                              ],
                            ),
                          ),
                          Expanded(flex: 1, child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                  );
                }

                final isDir = FileSystemEntity.isDirectorySync(path);
                final isSvg = path.toLowerCase().endsWith('.svg');
                DateTime? modified;

                try {
                  modified = File(path).lastModifiedSync();
                } catch (_) {}
                return Draggable<FileSystemEntity>(
                  data: entity,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: _buildFileRow(context, entity, name, isDir, isSvg, modified),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (isDir) {
                        onDirectoryTap(path);
                      } else {
                        onFileTap(entity);
                      }
                    },
                    child: _buildFileRow(context, entity, name, isDir, isSvg, modified),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileRow(BuildContext context, FileSystemEntity entity, String name, bool isDir, bool isSvg, DateTime? modified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: isDir
                      ? const Icon(Icons.folder_outlined, size: 20)
                      : isSvg
                          ? SvgPicture.file(File(entity.path), width: 20, height: 20)
                          : const Icon(Icons.insert_drive_file_outlined, size: 20),
                ),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
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
    );
  }
}
