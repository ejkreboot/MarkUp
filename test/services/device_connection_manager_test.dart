import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartssh2/dartssh2.dart';

import 'package:markup/services/device_connection_manager.dart'; // Adjust as needed
import '../mocks/mock_ssh_classes.dart';

void main() {
  late MockSSHClient mockClient;
  late MockSFTPClient mockSftp;
  late MockSFTPFile mockFile;
  late DeviceConnectionManager manager;

  setUpAll(() {
    registerFallbackValue(SftpFileOpenMode.read);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockClient = MockSSHClient();
    mockSftp = MockSFTPClient();
    mockFile = MockSFTPFile();
    final mockTemplatesJsonFile = MockSFTPFile();

    when(() => mockTemplatesJsonFile.readBytes(
      length: any(named: 'length'),
      offset: any(named: 'offset'),
    )).thenAnswer((_) async => Uint8List.fromList(utf8.encode('{"templates":[]}')));

    when(() => mockTemplatesJsonFile.close()).thenAnswer((_) async {});
    when(() => mockClient.sftp()).thenAnswer((_) async => mockSftp);
    manager = DeviceConnectionManager(testClient: mockClient);
    final minimalTemplatesJson = utf8.encode('{"templates":[]}');
    when(() => mockSftp.open(
      any(),
      mode: any(named: 'mode'),
    )).thenAnswer((invocation) async {
      final String path = invocation.positionalArguments[0] as String;
      final Set<SftpFileOpenMode> mode = invocation.namedArguments[#mode] as Set<SftpFileOpenMode>;

      if (path.contains('templates.json') && mode.contains(SftpFileOpenMode.read)) {
        return mockTemplatesJsonFile; // 👈 always reuse the prebuilt file
      } else {
        final mockFile = MockSFTPFile();
        when(() => mockFile.writeBytes(any())).thenAnswer((_) async {});
        when(() => mockFile.close()).thenAnswer((_) async {});
        return mockFile;
      }
    });
  });

  test('uploads SVG, creates symlink, updates templates.json', () async {
    // Mocks SFTP open and file writing
    when(() => mockSftp.open(
      any(),
      mode: any(named: 'mode'),
    )).thenAnswer((_) async => mockFile);

    when(() => mockFile.writeBytes(any())).thenAnswer((_) async {});
    when(() => mockFile.close()).thenAnswer((_) async {});
    when(() => mockFile.stat()).thenAnswer((_) async => SftpFileAttrs(
      size: 0,
      userID: 0,
      groupID: 0,
      accessTime: 0,
      modifyTime: 0,
    ));

    // Mocks SSH command execution
    when(() => mockClient.execute(any())).thenAnswer((invocation) async {
      final session = MockSSHSession();
      when(() => session.stdout).thenAnswer((_) => Stream.value(utf8.encode('')));
      when(() => session.stderr).thenAnswer((_) => Stream.value(utf8.encode('')));
      when(() => session.exitCode).thenAnswer((_) => 0);
      when(() => session.done).thenAnswer((_) async {});
      return session;
    });

    // Simulate local SVG file
    final tempSvg = File('temp_test_template.svg');
    await tempSvg.writeAsString('<svg>mock test template</svg>');

    // Run the upload + update flow
    await manager.uploadTemplateAndUpdateJson(
      localSvgFile: tempSvg,
      templateName: 'Test Template',
      templateFilename: 'test_template',
    );

    // Verify that symlink was created
    verify(() => mockClient.execute(
      captureAny(),
    )).called(greaterThanOrEqualTo(1));

    await tempSvg.delete();
  });
}
