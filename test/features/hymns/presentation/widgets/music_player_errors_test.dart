import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_reference.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/music_player_widget.dart';

const _audioUrl = 'https://api.example.test/api/v1/songs/am-sda-2004-0004/'
    'audio/file?language=am&version=am-sda-2004';

/// A hymn whose audio is on the server and not on the phone.
class _RemoteAudio implements AudioMediaRepository {
  @override
  AudioTrack? getTrackForHymn(Hymn hymn) => null;

  @override
  AudioTrack? getTrackForNumber(
    int hymnNumber, {
    String? title,
    String version = 'sda_new',
    String? mediaSource,
  }) =>
      AudioTrack(
        hymnNumber: hymnNumber,
        title: title ?? '',
        source: MediaReference.tryParse(mediaSource)!,
      );

  @override
  Future<String?> cachedPathFor(MediaSource source) async => null;
}

/// Downloads that fail with whatever [failure] returns.
class _FailingDownloads implements MediaDownloadRepository {
  _FailingDownloads(this.failure);

  Object Function() failure;
  int requests = 0;

  @override
  Future<bool> isDownloadAvailable(String mediaType, MediaSource? source) =>
      Future.value(true);

  @override
  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required MediaSource source,
    void Function(int received, int? total)? onProgress,
  }) async {
    requests++;
    throw failure();
  }

  @override
  Future<bool> deleteDownload(String mediaType, MediaSource source) =>
      Future.value(false);

  @override
  Future<void> clearDownloads(String mediaType) async {}
}

const _noInternet = 'የኢንተርኔት ግንኙነት የለም። ግንኙነትዎን አረጋግጠው እንደገና ይሞክሩ።';
const _couldNotOpen = 'ድምፁን መክፈት አልተቻለም። እባክዎ እንደገና ይሞክሩ።';

void main() {
  Future<void> pumpPlayer(
    WidgetTester tester,
    _FailingDownloads downloads,
  ) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MusicPlayerWidget(
              hymnNumber: 4,
              hymnTitle: 'ይህች ቀን ናት',
              audioSource: _audioUrl,
              version: 'sda_new',
              audioRepository: _RemoteAudio(),
              downloadRepository: downloads,
            ),
          ),
        ),
      );

  /// Not pumpAndSettle: the player shows a spinner while it loads, and a
  /// spinner never settles.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Taps play and agrees to the download.
  Future<void> playAndDownload(WidgetTester tester) async {
    await tester.tap(find.byTooltip('አጫውት'));
    await pumpFrames(tester);
    await tester.tap(find.text('አውርድ'));
    await pumpFrames(tester);
  }

  /// Every piece of text on screen, joined.
  String everythingShown(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .join('\n');

  testWidgets('no internet is said plainly, once, without technical detail',
      (tester) async {
    // What an iPhone with a signal but no working data reports.
    final downloads = _FailingDownloads(
      () => SocketException(
        'Connection reset by peer',
        osError: const OSError('Connection reset by peer', 54),
        address: InternetAddress('203.0.113.7'),
        port: 64313,
      ),
    );
    await pumpPlayer(tester, downloads);

    await playAndDownload(tester);

    expect(find.text(_noInternet), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final shown = everythingShown(tester);
    for (final leak in [
      'SocketException',
      'Connection reset',
      'errno',
      'api.example.test',
      'https://',
    ]) {
      expect(shown, isNot(contains(leak)), reason: 'shows "$leak"');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the play button tries again after a failure', (tester) async {
    final downloads =
        _FailingDownloads(() => const SocketException('Network is down'));
    await pumpPlayer(tester, downloads);

    await playAndDownload(tester);
    expect(downloads.requests, 1);
    expect(find.text(_noInternet), findsOneWidget);

    // Something other than the network this time.
    downloads.failure = () => StateError('decoder refused the file');
    await playAndDownload(tester);

    expect(downloads.requests, 2);
    expect(find.text(_noInternet), findsNothing);
    expect(find.text(_couldNotOpen), findsOneWidget);
    expect(everythingShown(tester), isNot(contains('decoder')));
    expect(tester.takeException(), isNull);
  });
}
