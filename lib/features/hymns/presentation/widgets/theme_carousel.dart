import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme_spec.dart';

/// The row of theme circles, and one name under it.
///
/// The row snaps, so the chosen theme is always the middle circle and the
/// name below belongs to it. That is what lets the app offer a dozen
/// themes without a dozen labels crowding the page.
///
/// The choice is made when the row comes to rest, not while it is moving:
/// a flick past ten circles repaints the app once, at the end, instead of
/// ten times on the way.
class ThemeCarousel extends StatefulWidget {
  final ThemeService theme;

  const ThemeCarousel({super.key, required this.theme});

  @override
  State<ThemeCarousel> createState() => _ThemeCarouselState();
}

class _ThemeCarouselState extends State<ThemeCarousel> {
  /// Roughly four and a half circles across, so it is plain that the row
  /// carries on in both directions.
  static const double _viewportFraction = 0.22;
  static const double _rowHeight = 58;

  late final PageController _controller;
  late int _centred;

  @override
  void initState() {
    super.initState();
    _centred = AppThemeCatalog.indexOf(widget.theme.palette);
    _controller = PageController(
      initialPage: _centred,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Takes the choice once the row has stopped somewhere.
  void _settle() {
    final chosen = AppThemeCatalog.themes[_centred];
    if (chosen.id != widget.theme.palette) {
      widget.theme.setPalette(chosen.id);
    }
  }

  void _bringToCentre(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    // Somewhere other than the row changed the theme — follow it.
    final chosenIndex = AppThemeCatalog.indexOf(widget.theme.palette);
    // `position` only exists once the row has been laid out, so a change
    // that arrives before the first frame just moves the mark.
    final settled = !_controller.hasClients ||
        !_controller.position.isScrollingNotifier.value;
    if (chosenIndex != _centred && settled) {
      _centred = chosenIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _bringToCentre(chosenIndex);
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _rowHeight,
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              _settle();
              return false;
            },
            child: PageView.builder(
              key: const ValueKey('theme-carousel'),
              controller: _controller,
              itemCount: AppThemeCatalog.themes.length,
              onPageChanged: (index) => setState(() => _centred = index),
              itemBuilder: (context, index) {
                final spec = AppThemeCatalog.themes[index];
                return _ThemeSwatch(
                  spec: spec,
                  centred: index == _centred,
                  colors: colors,
                  brightness: brightness,
                  onTap: () => _bringToCentre(index),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            AppThemeCatalog.themes[_centred]
                .labelFor(Localizations.maybeLocaleOf(context)),
            key: ValueKey(
                'theme-name-${AppThemeCatalog.themes[_centred].id.name}'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}

/// One circle: the theme's own colours, ringed when it is the chosen one.
class _ThemeSwatch extends StatelessWidget {
  final AppThemeSpec spec;
  final bool centred;
  final AppColorsExtension colors;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.spec,
    required this.centred,
    required this.colors,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The tick is drawn in the ink that theme puts on its own accent, so
    // it stays readable on a pale gold and on a deep blue alike.
    final tick = spec.colorsFor(brightness).onAccent;

    return Semantics(
      button: true,
      selected: centred,
      label: spec.labelFor(Localizations.maybeLocaleOf(context)),
      excludeSemantics: true,
      child: Center(
        child: InkWell(
          key: ValueKey('theme-palette-${spec.id.name}'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: centred ? colors.primaryText : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: spec.swatch.gradient,
                border: Border.all(color: colors.divider),
              ),
              child: centred
                  ? Icon(Icons.check, size: 20, color: tick)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
