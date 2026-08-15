import 'dart:io';

import 'package:blaze_drop/features/server/data/datasources/device_media_store.dart';
import 'package:blaze_drop/features/server/domain/entities/downloaded_file.dart';
import 'package:blaze_drop/features/server/domain/exceptions/server_transfer_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceMediaStore.targetFor', () {
    test('routes photos to the gallery', () {
      expect(DeviceMediaStore.targetFor('photo.png'), DownloadTarget.gallery);
      expect(DeviceMediaStore.targetFor('pic.JPG'), DownloadTarget.gallery);
      expect(DeviceMediaStore.targetFor('art.svg'), DownloadTarget.gallery);
      expect(DeviceMediaStore.targetFor('scan.heic'), DownloadTarget.gallery);
    });

    test('routes everything else to documents', () {
      expect(DeviceMediaStore.targetFor('doc.pdf'), DownloadTarget.documents);
      expect(DeviceMediaStore.targetFor('archive.zip'), DownloadTarget.documents);
      expect(DeviceMediaStore.targetFor('movie.mp4'), DownloadTarget.documents);
      expect(DeviceMediaStore.targetFor('config.yaml'), DownloadTarget.documents);
      expect(DeviceMediaStore.targetFor('unknown.xyz'), DownloadTarget.documents);
    });
  });

  group('DeviceMediaStore.store', () {
    late Directory tempDir;
    late Directory documentsDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('blazedrop_media_test');
      documentsDir = await Directory.systemTemp.createTemp(
        'blazedrop_docs_test',
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
      await documentsDir.delete(recursive: true);
    });

    test('copies non-image files into the documents folder', () async {
      final store = DeviceMediaStore(
        documentsDirectoryProvider: () async => documentsDir.path,
      );
      final source = File('${tempDir.path}/notes.txt');
      await source.writeAsString('hello');

      final result = await store.store(
        sourcePath: source.path,
        fileName: 'notes.txt',
      );

      expect(result.target, DownloadTarget.documents);
      expect(result.name, 'notes.txt');
      expect(result.path, '${documentsDir.path}/notes.txt');
      expect(
        await File('${documentsDir.path}/notes.txt').readAsString(),
        'hello',
      );
    });

    test('resolves name collisions in the documents folder', () async {
      final store = DeviceMediaStore(
        documentsDirectoryProvider: () async => documentsDir.path,
      );
      final source = File('${tempDir.path}/notes.txt');
      await source.writeAsString('v1');
      await File('${documentsDir.path}/notes.txt').writeAsString('existing');

      final result = await store.store(
        sourcePath: source.path,
        fileName: 'notes.txt',
      );

      expect(result.name, 'notes (1).txt');
      expect(
        await File('${documentsDir.path}/notes (1).txt').readAsString(),
        'v1',
      );
    });

    test('routes photos to the gallery (plugin unavailable → clear error)',
        () async {
      final store = DeviceMediaStore(
        documentsDirectoryProvider: () async => documentsDir.path,
      );
      final source = File('${tempDir.path}/photo.png');
      await source.writeAsBytes(<int>[1, 2, 3]);

      // `gal` is not registered in the unit-test environment, so the gallery
      // branch surfaces a user-presentable error instead of crashing.
      expect(
        () => store.store(sourcePath: source.path, fileName: 'photo.png'),
        throwsA(isA<ServerTransferException>()),
      );
    });
  });
}
