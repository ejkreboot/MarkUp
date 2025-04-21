import 'package:mocktail/mocktail.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';

// Mock classes
class MockSSHClient extends Mock implements SSHClient {}

class MockSFTPClient extends Mock implements SftpClient {}

class MockSSHSession extends Mock implements SSHSession {}

class MockSFTPFile extends Mock implements SftpFile {
  @override
  Future<Uint8List> readBytes({int? length, int offset = 0}) async {
    return Uint8List(0); // Return empty bytes for testing
  }
}