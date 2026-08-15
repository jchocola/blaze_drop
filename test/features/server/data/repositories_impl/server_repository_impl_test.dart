import 'dart:async';

import 'package:blaze_drop/features/server/data/datasources/host_file_picker.dart';
import 'package:blaze_drop/features/server/data/datasources/web_server_transport.dart';
import 'package:blaze_drop/features/server/data/repositories_impl/server_repository_impl.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/host_publish_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_shared_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransport extends Mock implements WebServerTransport {}

class _MockHostFilePicker extends Mock implements HostFilePicker {}

void main() {
  group('ServerRepositoryImpl', () {
    late _MockTransport transport;
    late _MockHostFilePicker filePicker;

    setUp(() {
      transport = _MockTransport();
      filePicker = _MockHostFilePicker();
    });

    ServerRepositoryImpl buildRepository() {
      return ServerRepositoryImpl(transport: transport, filePicker: filePicker);
    }

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

      final repository = buildRepository();
      final result = await repository.startServer(sessionTimeoutMinutes: 20);

      expect(result, session);
      verify(
        () => transport.start(preferredPort: 8080, sessionTimeoutMinutes: 20),
      ).called(1);
    });

    test('delegates stop / refresh / streams / listing / getters', () async {
      final repository = buildRepository();
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

    test('delegates pick / publish / download to the host picker + transport',
        () async {
      final repository = buildRepository();
      const staged = HostPublishFile(
        name: 'deploy.zip',
        path: '/tmp/deploy.zip',
        size: 42,
      );
      const published = ServerSharedFile(
        id: 'deploy.zip',
        name: 'deploy.zip',
        path: '/shared/deploy.zip',
        size: 42,
      );

      when(() => filePicker.pickFiles()).thenAnswer((_) async => [staged]);
      when(
        () => transport.publishFiles(any()),
      ).thenAnswer((_) async => [published]);
      when(
        () => transport.downloadSharedFile(any()),
      ).thenAnswer((_) async => published);

      expect(await repository.pickHostFiles(), [staged]);
      expect(await repository.publishFiles(const [staged]), [published]);
      expect(await repository.downloadSharedFile('deploy.zip'), published);

      verify(() => filePicker.pickFiles()).called(1);
      verify(() => transport.publishFiles(const [staged])).called(1);
      verify(() => transport.downloadSharedFile('deploy.zip')).called(1);
    });
  });
}
