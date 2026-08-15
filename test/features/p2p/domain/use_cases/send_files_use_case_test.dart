import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:blaze_drop/features/p2p/domain/entities/transfer_session.dart';
import 'package:blaze_drop/features/p2p/domain/repositories/peer_repository.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/send_files_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPeerRepository extends Mock implements PeerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const PeerDevice(
        id: 'fb',
        name: 'FALLBACK',
        ipAddress: '0.0.0.0',
        servicePort: 1,
      ),
    );
    registerFallbackValue(const <FileItem>[]);
  });

  group('SendFilesUseCase', () {
    late _MockPeerRepository repository;
    late SendFilesUseCase useCase;

    setUp(() {
      repository = _MockPeerRepository();
      useCase = SendFilesUseCase(repository);
    });

    test('delegates to the repository and forwards progress', () async {
      const peer = PeerDevice(
        id: 'node-1',
        name: 'ONYX_RIG',
        ipAddress: '192.168.1.45',
        servicePort: 43211,
      );
      const files = [
        FileItem(name: 'a.zip', path: '/tmp/a.zip', size: 100),
      ];
      final completed = TransferSession(
        sessionId: 's-1',
        peer: peer,
        direction: TransferDirection.outgoing,
        files: files,
        status: TransferStatus.completed,
        progress: 1,
        bytesTotal: 100,
        bytesTransferred: 100,
      );
      var progressCalls = 0;
      when(
        () => repository.sendFiles(
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.namedArguments[#onProgress]
            as void Function(int, int)?;
        cb?.call(50, 100);
        return completed;
      });

      final result = await useCase.execute(
        peer,
        files,
        onProgress: (transferred, total) {
          progressCalls++;
          expect(transferred, 50);
          expect(total, 100);
        },
      );

      expect(result, completed);
      expect(progressCalls, 1);
      verify(
        () => repository.sendFiles(
          peer,
          files,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
    });
  });
}
