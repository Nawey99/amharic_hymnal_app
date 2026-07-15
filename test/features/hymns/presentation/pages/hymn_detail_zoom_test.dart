import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/hymn_detail_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late HymnsBloc hymnsBloc;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'hagerigna',
      'sort_type': 'number',
    });
    await di.initDependencies(startDatabase: false);
  });

  setUp(() async {
    await di.sl<SettingsRepository>().setFavoriteHymns([]);
    await FontSizeService().setFontSize(20);
    hymnsBloc = di.sl<HymnsBloc>();
  });

  tearDown(() {
    hymnsBloc.close();
  });

  testWidgets('pinch zoom updates shared setting over selectable lyrics',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const lyrics = 'የመጀመሪያ መስመር\nሁለተኛ መስመር\nሦስተኛ መስመር';
    const hymn = Hymn(
      id: 'hagerigna-1',
      number: 1,
      title: 'የሙከራ መዝሙር',
      song: lyrics,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: hymnsBloc,
          child: const HymnDetailPage(hymn: hymn),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final lyricsFinder = find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == lyrics,
    );
    final initialText = tester.widget<SelectableText>(lyricsFinder);
    final initialFontSize = initialText.style!.fontSize!;
    final center = tester.getCenter(lyricsFinder);

    final firstFinger = await tester.startGesture(
      center.translate(-24, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      center.translate(24, 0),
      pointer: 2,
    );
    addTearDown(firstFinger.removePointer);
    addTearDown(secondFinger.removePointer);
    await tester.pump();
    await firstFinger.moveTo(center.translate(-72, 0));
    await secondFinger.moveTo(center.translate(72, 0));
    await tester.pump();
    await firstFinger.up();
    await tester.pump();
    await secondFinger.up();
    await tester.pump();
    await tester.pumpAndSettle();

    final zoomedText = tester.widget<SelectableText>(lyricsFinder);
    expect(zoomedText.style!.fontSize, greaterThan(initialFontSize));
    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byType(SingleChildScrollView),
          )
          .physics,
      isNull,
    );
    expect(
      FontSizeService().getFontSize(),
      closeTo(zoomedText.style!.fontSize!, 0.01),
    );
    expect(
      di.sl<SettingsRepository>().getFontSize(),
      closeTo(zoomedText.style!.fontSize!, 0.01),
    );
  });

  testWidgets('one-finger lyrics scrolling remains available', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final lyrics = List.generate(
      40,
      (index) => 'የመዝሙር መስመር ${index + 1}',
    ).join('\n');
    final hymn = Hymn(
      id: 'hagerigna-2',
      number: 2,
      title: 'ረጅም የሙከራ መዝሙር',
      song: lyrics,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HymnsBloc>.value(
          value: hymnsBloc,
          child: HymnDetailPage(hymn: hymn),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final lyricsFinder = find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == lyrics,
    );
    final initialTop = tester.getTopLeft(lyricsFinder).dy;

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(lyricsFinder).dy, lessThan(initialTop));
  });
}
