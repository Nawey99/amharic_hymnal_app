import 'dart:convert';
import 'dart:io';

/// Responses recorded from the live hymnal API (trimmed to a few songs), so
/// tests exercise the real shapes without touching the network.
///
/// Refresh them from https://amharichymnalbackend.vercel.app/api/v1 (keep the
/// trimmed samples small) when the backend's contract changes; the contract
/// tests in test/contract/ then show what the app must adapt to.
Map<String, dynamic> apiFixture(String name) =>
    jsonDecode(File('test/fixtures/api/$name').readAsStringSync())
        as Map<String, dynamic>;

/// The `data` payload of a recorded `{ success, data }` response.
T apiFixtureData<T>(String name) => apiFixture(name)['data'] as T;

/// The raw text of a recorded response.
String apiFixtureText(String name) =>
    File('test/fixtures/api/$name').readAsStringSync();
