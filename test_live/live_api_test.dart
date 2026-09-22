// Checks against the LIVE hymnal API. Not part of `flutter test` (which only
// runs test/); the nightly workflow runs them with:
//
//   flutter test test_live
//
// They read production (never write) and report problems with the content or
// the contract the app depends on. A failure here does not mean the app code
// is wrong; it means production changed and someone should look.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/app_update_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_version_service.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/core/services/song_editions_service.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';

void main() {
  late Directory root;

  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('live_api');
  });
  tearDownAll(() async => root.delete(recursive: true));

  HymnRemoteDataSource source() => HymnRemoteDataSource(
        store: FileEditionStore(directoryProvider: () async => root),
        mediaCache: LocalMediaCacheService(directoryProvider: () async => root),
      );

  test('every edition loads, and counts match what the API advertises',
      () async {
    final versions = await HymnalVersionService().refresh();
    expect(versions.length, greaterThanOrEqualTo(4));

    for (final version in versions) {
      final hymns = await source().getHymns('am', version.id);
      expect(hymns, isNotEmpty, reason: '${version.id} returned no hymns');
      for (final hymn in hymns) {
        expect(hymn.title?.trim(), isNotEmpty, reason: '${hymn.id} title');
        expect(hymn.lyrics?.trim(), isNotEmpty, reason: '${hymn.id} lyrics');
        expect(hymn.audioInfo?.file.checksumSha256 ?? 'x' * 64, hasLength(64),
            reason: '${hymn.id} audio checksum');
        for (final page in hymn.sheetPages ?? const []) {
          expect(page.file.checksumSha256, hasLength(64),
              reason: '${hymn.id} page ${page.pageNumber} checksum');
        }
      }
      // ignore: avoid_print
      print('${version.id}: ${hymns.length} hymns');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a random sample of pages and tracks downloads and verifies', () async {
    final cache = LocalMediaCacheService(directoryProvider: () async => root);
    final random = Random();
    for (final id in [HymnalVersions.sdaNew, HymnalVersions.sdaOld]) {
      final hymns = await source().getHymns('am', id);
      final withPages = hymns.where((h) => h.sheetPages != null).toList();
      final withAudio = hymns.where((h) => h.audioInfo != null).toList();
      for (var i = 0; i < 3; i++) {
        final page =
            withPages[random.nextInt(withPages.length)].sheetPages!.first;
        await cache.download(
            mediaSourceForFile(page.file), MediaType.sheetMusic);
        final track = withAudio[random.nextInt(withAudio.length)].audioInfo!;
        await cache.download(mediaSourceForFile(track.file), MediaType.audio);
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a delta from an older point equals a full download', () async {
    final store = FileEditionStore(directoryProvider: () async => root);
    final full = await HymnRemoteDataSource(store: store)
        .getHymns('am', HymnalVersions.sdaNew);
    final key = 'am_${HymnalVersions.apiCode(HymnalVersions.sdaNew)}';
    final stored = (await store.read(key))!;
    await store.write(
      key,
      StoredEdition(
        code: stored.code,
        contentUpdatedAt: 'older',
        serverTime: DateTime.now()
            .toUtc()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
        fullSyncAt: DateTime.now().toUtc(),
        songs: stored.songs,
      ),
    );

    final patched = await HymnRemoteDataSource(store: store)
        .getHymns('am', HymnalVersions.sdaNew);

    expect(patched.map((h) => '${h.id}|${h.title}|${h.lyrics}'),
        full.map((h) => '${h.id}|${h.title}|${h.lyrics}'));
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('other editions and the manifest answer', () async {
    final others =
        await SongEditionsService().otherEditions('am-sda-1975-0130');
    expect(others.map((e) => e.versionCode), contains('am-sda-2004'));
    // Null means "no update required"; the call itself must succeed.
    await AppUpdateService(currentVersion: () async => '999.0.0')
        .requiredVersion('am-sda-2004');
  });
}
