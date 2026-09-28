import 'package:flutter/scheduler.dart';

/// Temporary: prints how long frames take to build and to raster.
///
/// Off unless the app is built with
/// `--dart-define=WUDASE_FRAME_STATS=true`.
class FrameStatsProbe {
  static const _enabled =
      bool.fromEnvironment('WUDASE_FRAME_STATS', defaultValue: false);

  static final List<FrameTiming> _frames = [];

  static void start() {
    if (!_enabled) return;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      _frames.addAll(timings);
      if (_frames.length >= 60) _report();
    });
  }

  static void _report() {
    final build = _frames
        .map((f) => f.buildDuration.inMicroseconds / 1000)
        .toList()
      ..sort();
    final raster = _frames
        .map((f) => f.rasterDuration.inMicroseconds / 1000)
        .toList()
      ..sort();
    final total = _frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList()
      ..sort();
    double p(List<double> xs, double at) =>
        xs[(xs.length * at).clamp(0, xs.length - 1).toInt()];
    final janky = total.where((t) => t > 16.7).length;

    // ignore: avoid_print
    print(
      'FRAMESTATS n=${_frames.length} '
      'build p50=${p(build, .5).toStringAsFixed(1)} '
      'p90=${p(build, .9).toStringAsFixed(1)} '
      'p99=${p(build, .99).toStringAsFixed(1)} | '
      'raster p50=${p(raster, .5).toStringAsFixed(1)} '
      'p90=${p(raster, .9).toStringAsFixed(1)} '
      'p99=${p(raster, .99).toStringAsFixed(1)} | '
      'over16.7=$janky/${total.length}',
    );
    _frames.clear();
  }
}
