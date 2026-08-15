import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBytes', () {
    test('formats bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(512), '512 B');
    });

    test('formats kilobytes', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(2048), '2.0 KB');
    });

    test('formats megabytes', () {
      expect(formatBytes(14 * 1024 * 1024), '14.0 MB');
      expect(formatBytes(890 * 1024 * 1024), '890 MB');
    });

    test('formats gigabytes', () {
      expect(formatBytes((5 * 1024 * 1024 * 1024).round()), '5.0 GB');
    });
  });

  group('FileItem', () {
    test('sizeLabel uses formatBytes', () {
      const item = FileItem(
        name: 'a.dat',
        path: '/tmp/a.dat',
        size: 14 * 1024 * 1024,
      );
      expect(item.sizeLabel, '14.0 MB');
    });

    test('copyWith overrides only provided fields', () {
      const item = FileItem(
        name: 'a.dat',
        path: '/tmp/a.dat',
        size: 10,
        mimeType: 'application/octet-stream',
      );
      final renamed = item.copyWith(name: 'b.dat');
      expect(renamed.name, 'b.dat');
      expect(renamed.path, '/tmp/a.dat');
      expect(renamed.size, 10);
      expect(renamed.mimeType, 'application/octet-stream');
    });
  });
}
