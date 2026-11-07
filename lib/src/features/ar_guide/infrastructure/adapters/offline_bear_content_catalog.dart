import 'dart:convert';

import 'package:flutter/services.dart';

/// Resolves the printed BIOINNOVA QR identifiers from the bundled catalog.
class OfflineBearContentCatalog {
  OfflineBearContentCatalog._(this._points);

  final Map<String, Map<String, dynamic>> _points;

  static Future<OfflineBearContentCatalog> load() async {
    final source = await rootBundle.loadString(
      'assets/content/oso_contenido.json',
    );
    final document = jsonDecode(source) as Map<String, dynamic>;
    final points = <String, Map<String, dynamic>>{};
    for (final raw in document['puntos'] as List<dynamic>) {
      final point = Map<String, dynamic>.from(raw as Map);
      points[point['id'] as String] = point;
    }
    return OfflineBearContentCatalog._(points);
  }

  Map<String, dynamic>? pointForQr(String payload) {
    const prefix = 'BIOINNOVA:';
    if (!payload.startsWith(prefix)) return null;
    return _points[payload.substring(prefix.length)];
  }

  bool isValidated(Map<String, dynamic> point) =>
      point['fuente'] != 'por_validar';
}
