Часть 1. AES-256-GCM для P2P-транспорта (§7)
1.1 Выбор пакета
Спека называет pointycastle, но я рекомендую cryptography (от dint.dev):

Задача	cryptography	pointycastle
X25519 (обмен ключами)	X25519()	есть, но много boilerplate
HKDF-SHA256	Hkdf(hmac: Hmac.sha256())	руками
AES-256-GCM	AesGcm.with256bits()	есть, но легко ошибиться в параметрах
cryptography — чистый Dart (работает на всех платформах, включая тесты на VM), API высокоуровневый и безопасный по умолчанию.
1.2 Ключевой обмен на этапе handshake
Схема — эфемерный X25519 + HKDF (новый ключ на каждую сессию → forward secrecy):

import 'package:cryptography/cryptography.dart';

// Обе стороны, в момент установки TCP-соединения, ДО кадра `hello`:
final algorithm = X25519();
final keyPair = await algorithm.newKeyPair();
final pubBase64 = base64Encode(await keyPair.extractPublicKey());

// Обмен публичными ключами (открытыми — они не секретны):
//  клиент → сервер: {"type":"key_offer","pub":pubBase64}
//  сервер → клиент: {"type":"key_accept","pub":pubBase64}

// Обе стороны вычисляют общий секрет:
final secret = await algorithm.sharedSecretKey(
  keyPair: keyPair,
  remotePublicKey: SimplePublicKey(base64Decode(remotePub), type: KeyPairType.x25519),
);

// HKDF-SHA256 → 32 байта ключа AES-256 + 12 байт базового nonce:
final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32 + 12);
final derived = await hkdf.deriveKey(
  secretKey: secret,
  nonce: utf8.encode(sessionId),        // salt
  info: utf8.encode('blazedrop/aes256gcm/v1'),
);
final keyBytes = await derived.extractBytes(); // [0..32) — ключ, [32..44) — базовый nonce


1.3 ⚠️ MITM на сам обмен — обязательно продумать
Голый DH не аутентифицирует стороны — атакующий между устройствами подменит ключи. Практичные решения (как в AirDrop/Signal):

SAS-подтверждение: после обмена обе стороны показывают короткий код sha256(pubA || pubB)[0..6] (например A7F3-9B). Принимающая сторона подтверждает в оверлее перед ACCEPT. Это уже есть куда встроить — в IncomingRequestOverlay добавить строку «Verify code: A7F3-9B».
QR-подтверждение: отправитель кодирует свой публичный ключ/отпечаток в QR, получатель сканирует и сверяет.
Для MVP достаточно SAS-подтверждения; шифрование без него защищает только от пассивного прослушивания, но не от MITM.

1.4 Фрейминг и nonce-менеджмент (самое критичное)
AES-GCM — AEAD: каждый пакет = ciphertext + 16-байтный MAC (tag), плюс свой nonce (12 байт). Главное правило: nonce никогда не должен повторяться с одним ключом — иначе GCM полностью ломается.

Формат фрейма на проводе:
┌──────────┬──────────┬──────────────────────┬──────────┐
│ len (4B) │ nonce(12B)│ ciphertext          │ tag (16B)│
└──────────┴──────────┴──────────────────────┴──────────┘
Nonce — это счётчик пакетов (монотонно растёт на каждый отправленный фрейм/чанк), а не случайность:


class _SecureChannel {
  _SecureChannel(this._key);
  final SecretKey _key; // 32 байта, из HKDF
  final _aesGcm = AesGcm.with256bits();
  int _counter = 0;

  Future<List<int>> encrypt(List<int> plaintext) async {
    final nonce = _nonceFor(_counter++);
    final box = await _aesGcm.encrypt(plaintext, nonce: nonce);
    // [len(4)] [nonce(12)] [cipher] [mac(16)]
    final payload = [...box.nonce, ...box.cipherText, ...box.mac.bytes];
    return [..._int32(payload.length), ...payload];
  }

  Future<List<int>> decrypt(List<int> frame) async {
    final nonce = frame.sublist(0, 12);
    final cipher = frame.sublist(12, frame.length - 16);
    final mac = Mac(frame.sublist(frame.length - 16));
    final box = SecretBox(cipher, nonce: nonce, mac: mac);
    return _aesGcm.decrypt(box, secretKey: _key);
  }

  List<int> _nonceFor(int i) {
    // 12 байт: 4 байта счётчика (big-endian) + 8 нулей — гарантированно уникально.
    final out = List<int>.filled(12, 0);
    out[3] = (i >> 24) & 0xFF;
    out[2] = (i >> 16) & 0xFF;
    out[1] = (i >> 8) & 0xFF;
    out[0] = i & 0xFF;
    return out;
  }
}


1.5 Точки интеграции в текущий PeerTransportImpl
Сейчас (peer_transport_impl.dart):

Контрольные кадры — _tryWriteJson(socket, {...}) пишет jsonEncode + '\n', а _readControl(reader) читает строку (строки 612–624).
Файловые чанки — отправитель делает socket.add(chunk) (строка ~545), получатель — reader.readBytes(want) (строка ~394).
Что меняем:

Добавляем обмен ключами до hello в sendFiles() (строки ~492) и в _handleIncoming() (строки ~303): сначала key_offer/key_accept, вычислить _SecureChannel, затем продолжать.
Заменяем фрейминг: вместо _tryWriteJson/_readControl — _channel.encrypt(utf8.encode(jsonEncode(map))) / _channel.decrypt(frame). _SocketReader остаётся, но читает length-prefixed блоки, а не строки.
Шифруем чанки файлов: socket.add(await _channel.encrypt(chunk)) и reader.readBytes(4) → length → readBytes(length) → decrypt. Размер на проводе растёт на 12+16 байт на чанк — несущественно.
Поднять версию протокола: PeerBeacon.protocolVersion = 2 + поле version в handshake, чтобы старый/новый клиент не «молча» падал, а показал «Protocol mismatch».
Где хранить _SecureChannel: поле транспорта на время активной сессии (рядом с _incomingSocket/_outgoingSocket).
Схема нового handshake:


1.6 Тесты (расширить существующий peer_transport_impl_test.dart)
Лучший тест на то, что всё действительно шифруется — MITM-сниффер:


test('traffic on the wire contains no plaintext metadata', () async {
  // Между A и B ставим "прокси"-сокет, который копирует байты и записывает их.
  // После завершения передачи проверяем:
  final wire = await File(wiretapPath).readAsBytes();
  final ascii = utf8.decode(wire, allowMalformed: true);
  expect(ascii.contains('hello'), isFalse);   // нет ни одного кадра в открытом виде
  expect(ascii.contains('payload.dat'), isFalse);
  expect(wire.where((b) => b == 0x7B /* '{' */).isEmpty, isTrue); // нет JSON
});


Часть 2. HTTPS для Server Mode (§7)

> ⛔ ОТКЛЮЧЕНО (2026-08-16). HTTPS/TLS убран из кода — Server Mode работает только по plain HTTP (`shelf_io.serve(handler, addr, port)` без `securityContext`). Удалены: `self_signed_certificate.dart`, `tls_certificate_provider.dart`, `ServerSession.isHttps/certFingerprint`, `GET /ca.pem`, баннер «INSTALL CA» в web-клиенте, `pointycastle` из pubspec. QR/DIRECT CONNECT = `http://ip:port`. Раздел ниже остаётся как спецификация на будущее (если HTTPS вернут), но текущая реализация его не использует.

Сейчас ShelfWebServerTransport запускается через shelf_io.serve(handler, anyIPv4, port) — plain HTTP (shelf_web_server_transport.dart, строки 115–125).

2.1 Генерация self-signed сертификата
Пакет certificates (как в спеке) — чистый Dart, генерирует X.509 на лету. Либо pointycastle + basic_utils. Пример через certificates:

import 'package:certificates/certificates.dart';

// Один раз на старте сервера (или кэшируем в Documents).
final rsa = RSAKeyGenerator();
final key = await rsa.generate(2048);
final cert = CertificateBuilder()
  ..subjectCommonName = 'blazedrop.local'
  ..subjectAlternativeNames = [ipAddress, 'blazedrop.local']
  ..validFrom = DateTime.now()
  ..validTo = DateTime.now().add(const Duration(days: 365))
  ..publicKey = key.publicKey
  ..privateKey = key
  ..isCA = false;
final pem = cert.buildPem();   // cert + private key в PEM


2.2 Запуск HTTPS на shelf
shelf_io.serve принимает SecurityContext:


final context = SecurityContext()
  ..useCertificateChainBytes(utf8.encode(certPem))
  ..usePrivateKeyBytes(utf8.encode(keyPem));

// В текущем цикле перебора портов (8080→8081→…) просто подставляем контекст:
server = await shelf_io.serve(
  handler,
  InternetAddress.anyIPv4,
  port,
  securityContext: context,   // ← единственное изменение
);


URL в ServerSession/QR меняется на https://IP:port.

2.3 Доверие (trust) — самый важный нюанс
Self-signed сертификат → браузер гостя покажет предупреждение «not secure». Функциональность §7 прямо требует: «the app validates the checksum». Значит:

В QR кодируем отпечаток сертификата: https://192.168.1.10:8080#sha256=<fingerprint>.
Приложение/веб-клиент после TLS-хендшейка сверяет отпечаток реального сертификата с тем, что в QR (certificate pinning / trust-on-first-use).
На клиенте (dio или HttpClient) — badCertificateCallback, который принимает сертификат только если его fingerprint совпал:

final client = HttpClient()
  ..badCertificateCallback = (cert, host, port) =>
      _sha256(cert.der) == expectedFingerprint;


      iOS ATS: в Info.plist добавить локальную сеть:
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key><true/>
  <key>NSExceptionDomains</key>
  <dict>
    <key>localhost</key><dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
    </dict>
  </dict>
</dict>


2.4 Точки изменения
Файл	Изменение
shelf_web_server_transport.dart	SecurityContext + shelf_io.serve(..., securityContext:); поле isHttps в ServerSession
qr_beacon.dart / server_page.dart	схема https:// + fingerprint в QR
web_client_assets.dart (app.js)	загрузка через https; проверка fingerprint из URL-хэша
Info.plist (iOS)	NSAllowsLocalNetworking
local_ip_resolver.dart	возвращать https URL

2.5 Тесты

test('server speaks TLS and rejects plain HTTP', () async {
  final transport = ShelfWebServerTransport(/* cert injected */);
  await transport.start(preferredPort: 0);

  final secure = HttpClient()
    ..badCertificateCallback = (_, _, _) => true; // тест-контекст
  final req = await secure.getUrl(Uri.parse('https://127.0.0.1:${transport.port}/'));
  expect((await req.close()).statusCode, 200);

  // plain HTTP на тот же порт должен упасть:
  expect(
    HttpClient().getUrl(Uri.parse('http://127.0.0.1:${transport.port}/')),
    throwsA(anything),
  );
});


Главные подводные камни (чтобы не сломать)
Nonce-счётчик — единственная реальная угроза: повтор nonce при AES-GCM = полная компрометация. Только монотонный счётчик, никогда random.
Шифровать по чанкам, а не весь файл одним блоком — иначе для 1 ГБ понадобится весь файл в памяти и нельзя будет резюмить/показывать прогресс.
Новый ключ на каждую сессию (эфемерный DH) — для forward secrecy; не хранить ключи на диске.
Bump версии протокола (PeerBeacon.protocolVersion) — старые сборки не поймут новый фрейминг, это надо явно детектить, а не ловить FormatException.
DH без SAS/QR-подтверждения — защита только от пассивного перехвата; активный MITM победит. SAS-код в оверлее приёма — минимум для «SECURE LINK» по-настоящему.