import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';

/// The app's name and version, quietly, at the foot of Settings.
///
/// It also hides the development section from people who would only open it
/// by accident: [unlockTaps] quick taps call [onUnlock], counting down aloud
/// for the last few; a long press calls [onHide] while [unlocked]. A pause
/// of [tapWindow] between taps starts the count again.
class AppVersionFooter extends StatefulWidget {
  static const int unlockTaps = 7;

  /// Taps before the countdown is shown, so a stray tap or two says nothing.
  static const int silentTaps = 3;

  static const Duration tapWindow = Duration(seconds: 2);

  final bool unlocked;
  final VoidCallback onUnlock;
  final VoidCallback onHide;

  /// The installed version; the platform's by default.
  final Future<String> Function()? loadVersion;

  const AppVersionFooter({
    super.key,
    required this.unlocked,
    required this.onUnlock,
    required this.onHide,
    this.loadVersion,
  });

  @override
  State<AppVersionFooter> createState() => _AppVersionFooterState();
}

class _AppVersionFooterState extends State<AppVersionFooter> {
  String? _version;
  int _taps = 0;
  Timer? _tapWindow;

  static Future<String> _platformVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final version = await (widget.loadVersion ?? _platformVersion)();
      if (mounted) setState(() => _version = version);
    } catch (_) {
      // Unknown version: the name alone is still shown.
    }
  }

  @override
  void dispose() {
    _tapWindow?.cancel();
    super.dispose();
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  void _handleTap() {
    _tapWindow?.cancel();
    _tapWindow = Timer(AppVersionFooter.tapWindow, () => _taps = 0);
    _taps++;

    if (widget.unlocked) {
      if (_taps == AppVersionFooter.unlockTaps) {
        _taps = 0;
        _say('የልማት ክፍሉ አስቀድሞ ይታያል።');
      }
      return;
    }

    final remaining = AppVersionFooter.unlockTaps - _taps;
    if (remaining == 0) {
      _taps = 0;
      _tapWindow?.cancel();
      widget.onUnlock();
      _say('የልማት ክፍሉ አሁን ይታያል።');
    } else if (_taps > AppVersionFooter.silentTaps) {
      _say('ለማሳየት $remaining ጊዜ ይንኩ።');
    }
  }

  void _handleLongPress() {
    if (!widget.unlocked) return;
    widget.onHide();
    _say('የልማት ክፍሉ ተደብቋል።');
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    return Semantics(
      // Read as plain information; the unlock is not an everyday control.
      excludeSemantics: true,
      label: version == null ? 'ውዳሴ' : 'ውዳሴ $version',
      child: GestureDetector(
        key: const ValueKey('app-version-footer'),
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Text(
              version == null ? 'ውዳሴ' : 'ውዳሴ · ስሪት $version',
              style: TextStyle(
                color: context.appColors.secondaryText.withValues(alpha: 0.8),
                fontSize: 12,
                fontFamily: 'NotoSansEthiopic',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
