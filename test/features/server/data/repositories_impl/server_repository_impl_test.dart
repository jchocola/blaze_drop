import 'dart:async';

import 'package:blaze_drop/features/server/data/datasources/web_server_transport.dart';
import 'package:blaze_drop/features/server/data/repositories_impl/server_repository_impl.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_shared_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransport extends Mock implements WebServerTransport {}

void main() {
  group('ServerRepositoryImpl', () {
    late _MockTransport transport;

    setUp(() {
      transport = _MockTransport();
    });

    test('startServer binds the default port with the given timeout', () async {
      const session = ServerSession(
        status: ServerStatus.active,
        port: 8080,
        localIp: '192.168.1.10',
      );
      when(
        () => transport.start(
          preferredPort: any(named: 'preferredPort'),
          sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes'),
        ),
      ).thenAnswer((_) async => session);

      final repository = ServerRepositoryImpl(transport: transport);
      final result = await repository.startServer(sessionTimeoutMinutes: 20);

      expect(result, session);
      verify(
        () => transport.start(preferredPort: 8080, sessionTimeoutMinutes: 20),
      ).called(1);
    });

    test('delegates stop / refresh / streams / listing / getters', () async {
      final repository = ServerRepositoryImpl(transport: transport);
      const file = ServerSharedFile(
        id: 'a.txt',
        name: 'a.txt',
        path: '/tmp/a.txt',
        size: 4,
      );
      final statusController = StreamController<ServerSession>.broadcast();
      final clientsController =
          StreamController<List<ConnectedClient>>.broadcast();
      final uploadsController =
          StreamController<ServerUploadEvent>.broadcast();

      when(() => transport.stop()).thenAnswer((_) async {});
      when(() => transport.refresh()).thenAnswer((_) async {});
      when(
        () => transport.watchStatus(),
      ).thenAnswer((_) => statusController.stream);
      when(
        () => transport.watchClients(),
      ).thenAnswer((_) => clientsController.stream);
      when(
        () => transport.watchUploads(),
      ).thenAnswer((_) => uploadsController.stream);
      when(() => transport.listFiles()).thenAnswer((_) async => [file]);
      when(
        () => transport.getLocalIp(),
      ).thenAnswer((_) async => '192.168.1.10');
      when(
        () => transport.getSharedDirectory(),
      ).thenAnswer((_) async => '/tmp');

      await repository.stopServer();
      await repository.refreshServer();

      final statusStream = repository.watchStatus();
      final clientsStream = repository.watchConnectedClients();
      final uploadsStream = repository.watchUploads();

      expect(statusStream, isA<Stream<ServerSession>>());
      expect(clientsStream, isA<Stream<List<ConnectedClient>>>());
      expect(uploadsStream, isA<Stream<ServerUploadEvent>>());
      expect(await repository.listSharedFiles(), [file]);
      expect(await repository.getLocalIp(), '192.168.1.10');
      expect(await repository.getSharedDirectory(), '/tmp');

      verify(() => transport.stop()).called(1);
      verify(() => transport.refresh()).called(1);
      verify(() => transport.watchStatus()).called(1);
      verify(() => transport.watchClients()).called(1);
      verify(() => transport.watchUploads()).called(1);
      verify(() => transport.listFiles()).called(1);
      verify(() => transport.getLocalIp()).called(1);
      verify(() => transport.getSharedDirectory()).called(1);

      await statusController.close();
      await clientsController.close();
      await uploadsController.close();
    });
  });
}
