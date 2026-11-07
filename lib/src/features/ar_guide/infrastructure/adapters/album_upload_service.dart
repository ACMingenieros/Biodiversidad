import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Sends a framed PNG to Biodiversidad's own photo album endpoint.
class AlbumUploadService {
  const AlbumUploadService({
    this.url = const String.fromEnvironment('BIODIVERSIDAD_ALBUM_UPLOAD_URL'),
  });

  final String url;

  bool get isConfigured {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> uploadPhoto(Uint8List bytes) async {
    if (!isConfigured) throw StateError('El álbum aún no está configurado');
    if (bytes.isEmpty) throw ArgumentError.value(bytes, 'bytes', 'Foto vacía');

    final destination = Uri.parse(url);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.postUrl(destination);
      request.headers.contentType = ContentType('image', 'png');
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.created) {
        String message = body;
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) message = decoded['error']?.toString() ?? body;
        } on FormatException {
          // The server may return plain text.
        }
        throw HttpException(message, uri: destination);
      }
    } finally {
      client.close(force: true);
    }
  }
}
