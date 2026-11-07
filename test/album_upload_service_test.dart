import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:biodiversidad/src/features/ar_guide/infrastructure/adapters/album_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('album upload stays unavailable without a Biodiversidad URL', () async {
    const service = AlbumUploadService(url: '');
    expect(service.isConfigured, isFalse);
    await expectLater(
      service.uploadPhoto(Uint8List.fromList([1])),
      throwsStateError,
    );
  });

  test(
    'album upload sends framed PNG bytes to the configured endpoint',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<List<int>>();
      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.headers.contentType?.mimeType, 'image/png');
        final bytes = await request.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );
        received.complete(bytes);
        request.response.statusCode = HttpStatus.created;
        await request.response.close();
      });
      try {
        final service = AlbumUploadService(
          url: 'http://127.0.0.1:${server.port}/api/upload.php',
        );
        final photo = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
        await service.uploadPhoto(photo);
        expect(await received.future, photo);
      } finally {
        await server.close(force: true);
      }
    },
  );
}
