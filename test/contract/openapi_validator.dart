import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';

/// Validates API bodies against the backend's published OpenAPI 3.1
/// contract (`test/fixtures/api/openapi.json`, a copy of
/// `GET /api/v1/openapi.json`).
///
/// OpenAPI 3.1 schemas are JSON Schema 2020-12, and their `$ref`s point at
/// `#/components/schemas/...`, so each schema is validated inside a root
/// document that carries the contract's `components`.
class OpenApiContract {
  OpenApiContract._(this.document);

  factory OpenApiContract.load([
    String path = 'test/fixtures/api/openapi.json',
  ]) =>
      OpenApiContract._(
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      );

  final Map<String, dynamic> document;
  final Map<String, JsonSchema> _compiled = {};

  Map<String, dynamic> get _schemas =>
      (document['components'] as Map<String, dynamic>)['schemas']
          as Map<String, dynamic>;

  /// The schema of a successful `GET` response body for [path]
  /// (e.g. `/api/v1/sync`).
  Map<String, dynamic> responseSchema(String path, {String status = '200'}) {
    final operation = (document['paths'] as Map<String, dynamic>)[path]?['get']
        as Map<String, dynamic>?;
    if (operation == null) throw ArgumentError('No GET $path in the contract');
    final response = (operation['responses'] as Map<String, dynamic>)[status]
        as Map<String, dynamic>;
    return ((response['content'] as Map<String, dynamic>)['application/json']
        as Map<String, dynamic>)['schema'] as Map<String, dynamic>;
  }

  /// Errors from validating [body] against the `GET` [path] response schema.
  List<String> validateResponse(String path, Object? body,
          {String status = '200'}) =>
      _validate(
          'response:$path:$status', responseSchema(path, status: status), body);

  /// Errors from validating [instance] against components/schemas/[name].
  List<String> validateComponent(String name, Object? instance) {
    if (!_schemas.containsKey(name)) {
      throw ArgumentError('No schema $name in the contract');
    }
    return _validate(
        'component:$name', {r'$ref': '#/components/schemas/$name'}, instance);
  }

  List<String> _validate(
    String key,
    Map<String, dynamic> schema,
    Object? instance,
  ) {
    final compiled = _compiled[key] ??= JsonSchema.create(
      {
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
        // Schemas only: other components (securitySchemes, responses) are
        // not JSON Schema and would not compile.
        'components': {'schemas': _schemas},
        ...schema,
      },
      schemaVersion: SchemaVersion.draft2020_12,
    );
    final result = compiled.validate(instance);
    return [for (final error in result.errors) error.toString()];
  }

  /// Whether components/schemas/[name] declares [dottedPath]
  /// (e.g. `audio.checksumSha256`, `sheetMusic.pages.borrowedFromVersionCode`),
  /// following `$ref`, `allOf`/`oneOf`/`anyOf` and array `items`.
  bool declares(String name, String dottedPath) {
    var candidates = <Map<String, dynamic>>[_schemas[name]];
    for (final segment in dottedPath.split('.')) {
      final next = <Map<String, dynamic>>[];
      for (final schema in candidates) {
        for (final variant in _variants(schema)) {
          final property = (variant['properties'] as Map?)?[segment];
          if (property is Map<String, dynamic>) {
            next.addAll(_variants(property).expand(_itemsOrSelf));
          }
        }
      }
      if (next.isEmpty) return false;
      candidates = next;
    }
    return true;
  }

  Iterable<Map<String, dynamic>> _itemsOrSelf(Map<String, dynamic> schema) {
    final items = schema['items'];
    return items is Map<String, dynamic> ? _variants(items) : [schema];
  }

  List<Map<String, dynamic>> _variants(Map<String, dynamic> schema) {
    final ref = schema[r'$ref'];
    if (ref is String) {
      return _variants(_schemas[ref.split('/').last] as Map<String, dynamic>);
    }
    return [
      schema,
      for (final keyword in const ['allOf', 'oneOf', 'anyOf'])
        for (final part in (schema[keyword] as List? ?? const []))
          ..._variants(part as Map<String, dynamic>),
    ];
  }
}
